require 'tempfile'
require 'open3'

class ServiceVersion < ApplicationRecord
  include S3Configuration
  include Rails.application.routes.url_helpers
  belongs_to :service
  belongs_to :user
  has_many :notifications, as: :subject
  validates :spec, swagger_spec: true
  before_create :set_version_number
  before_save :update_spec_with_resolved_refs
  after_save :update_search_metadata
  after_create :create_new_notification
  after_create :retract_proposed
  delegate :name, to: :service
  delegate :organization, to: :service

  # proposed: 0, current: 1, rejected: 2, retracted:3 , outdated:4 , retired:5
  #
  # The lifecycle is a follows:
  #
  # A new service version is born "proposed".
  # Until it is approved by GobiernoDigital, where it becomes "current".
  # Unless it is NOT approved, and it turns "rejected".
  # Or, the author decides to upload a new version before the approval or
  # rejection, in which case it becomes "retracted"
  # Also, once a subsequent version is accepted and becomes "current", the
  # previously current version becomes "outdated" if the change is backwards
  # compatible. If the change is NOT backwards compatible, it becomes "retired"
  #
  # ALWAYS add new states at the end.
  enum status: [:proposed, :current, :rejected, :retracted, :outdated, :retired]

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = YAML.safe_load(spec_file.read)
  end

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end

  def update_search_metadata
    service.update_search_metadata if status == "current"
  end

  def make_current_version
    self.current!
    update_old_versions_statuses
    create_state_change_notification(I18n.t(:approved))
  end

  def reject_version
    self.rejected!
    create_state_change_notification(I18n.t(:rejected))
  end

  def create_new_notification
    org = Organization.where(dipres_id: "AB01")
    if version_number == 1
      message = I18n.t(:create_new_service_notification, name: name)
    else
      message = I18n.t(:create_new_version_notification, name: name, version: version_number.to_s)
    end
    Role.where(name: "Service Provider", organization: org).each do |role|
      role.user.notifications.create(subject: self,
        message: message
      )
    end
  end

  def create_state_change_notification(status)
    org = Organization.where(dipres_id: "AB01")
    user.notifications.create(subject: self,
      message: I18n.t(:create_state_change_notification, name: name,
        version: self.version_number.to_s, status: status)
    )
  end

  def description
    spec['info']['description']
  end

  # Returns a hash where keys are tuples of [path, verb] and the values are
  # the swagger operations
  def operations
    ops = {}
    spec_with_resolved_refs['definition']['paths'].each do |path, verbs|
      verbs.except('parameters').each do |verb, operation|
        ops[[verb, path]] = operation
      end
    end
    ops
  end

  def operation(verb, path)
    spec_with_resolved_refs['definition']['paths'][path][verb]
  end

  def common_parameters_for_path(path)
    spec_with_resolved_refs['definition']['paths'][path]['parameters'] || []
  end

  def update_spec_with_resolved_refs
    output, _ = Open3.capture2("sway-resolve", :stdin_data => spec.to_json)
    # spec_with_resolved_refs will have two keys:
    # - `spec_with_resolved_refs['definition']`, will mirror `self.spec`
    #   but with all $refs replaced by the resolved/expanded content
    # - `spec_with_resolved_refs['references']` will contain a hash with an
    #   entry for every reference that has been resolved. Each entry in the hash
    #   will have the JSON Pointer of the parent element where a $ref was found
    #   as a key. And the value will include 'uri' (with the original ref URI),
    #  'type' (which can take the values 'local', 'remote'), among others. See
    #  the output of the sway-resolve command for more details.
    self.spec_with_resolved_refs = JSON.parse(output)
  end

  def update_old_versions_statuses
    if self.backwards_compatible?
      new_status = ServiceVersion.statuses[:outdated]
    else
      new_status = ServiceVersion.statuses[:retired]
    end
    service.service_versions.current.where(
      "version_number != ?", self.version_number).update_all(
      status: new_status)
  end

  def retract_proposed
    service.service_versions.proposed.where(
      "version_number != ?", self.version_number).each do |version|

        version.update(status: ServiceVersion.statuses[:retracted])
        version.notifications.update_all(read: true)
    end
  end

  # `langs` is an array containing any swagger-codegen generator.
  # Most used are:
  # java, php, csharp (for clients)
  # spring, slim, aspnet5 (for server stubs)
  def generate_zipped_code(langs)
    Dir.mktmpdir "service-version-#{id}-code" do |swagger_codegen_output_dir|
      with_spec_in_tmp_file do |spec_tmp_file|
        langs.each do |lang|
          lang_dir = File.join(swagger_codegen_output_dir, lang)
          Dir.mkdir lang_dir
          swagger_codegen spec_tmp_file.path, lang, lang_dir
        end
      end
      output_zip_name = "#{organization.name}-#{name}-r#{version_number}-#{langs.join('__')}.zip"
      with_tmp_file(output_zip_name) do |tmp_zip_file|
        ZipFileGenerator.new(swagger_codegen_output_dir, tmp_zip_file.path).write
        new_object = codegen_bucket.objects.build(output_zip_name)
        new_object.content = open(tmp_zip_file.path)
        new_object.acl = :public_read
        new_object.save
        return new_object.url
      end
    end
  end

  def with_tmp_file(name)
    tmp_file = Tempfile.new(name)
    yield(tmp_file)
  ensure
    if tmp_file
      tmp_file.close
      tmp_file.unlink
    end
  end

  def with_spec_in_tmp_file
    with_tmp_file("service-version-#{id}-spec") do |tmp_spec_file|
      tmp_spec_file.write self.spec.to_json
      tmp_spec_file.close
      yield(tmp_spec_file)
    end
  end

  def swagger_codegen(spec_file_path, lang, output_dir_path)
    Rails.logger.info(
      Open3.capture2e(
        "java", "-jar", Rails.root.join("vendor/swagger-codegen-cli.jar").to_s,
        "generate",
          "-i", spec_file_path,
          "-l", lang,
          "-o", output_dir_path,
      )
    )
  end

  def api_package_name
    self.name.titleize.gsub(/\s+/, '')
  end

  def url
    organization_service_service_version_path(self.organization, self.service, self)
  end

end
