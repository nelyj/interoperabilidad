require 'tempfile'
require 'open3'

class ServiceVersion < ApplicationRecord
  belongs_to :service
  belongs_to :user
  validates :spec, swagger_spec: true
  before_create :set_version_number
  after_save :update_search_metadata
  after_create :retract_proposed
  delegate :name, to: :service

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
  end

  def reject_version
    self.rejected!
  end

  def description
    spec['info']['description']
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
      "version_number != ?", self.version_number).update_all(
      status: ServiceVersion.statuses[:retracted])
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
      output_zip_name = "service-version-#{id}-#{langs.join('_')}.zip"
      with_tmp_file(output_zip_name) do |tmp_zip_file|
        ZipFileGenerator.new(swagger_codegen_output_dir, tmp_zip_file.path).write
        new_object = s3_bucket.objects.build(output_zip_name)
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

  def s3_bucket
    S3::Service.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    ).buckets.find(ENV['S3_CODEGEN_BUCKET'])
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
end
