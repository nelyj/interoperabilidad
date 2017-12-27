require 'tempfile'
require 'open3'

class ServiceVersion < ApplicationRecord
  include S3Configuration
  include Rails.application.routes.url_helpers
  belongs_to :service
  belongs_to :user
  has_many :notifications, as: :subject
  validates :spec, swagger_spec: true, presence: true
  before_create :set_version_number
  before_save :update_spec_with_resolved_refs
  validate :spec_file_must_be_parseable
  validates :custom_mock_service, :url => {:allow_blank => true}
  attr_accessor :spec_file_parse_exception
  after_save :update_search_metadata
  after_commit :schedule_health_checks
  after_create :create_new_notification
  after_create :retract_proposed
  delegate :name, to: :service
  delegate :organization, to: :service
  delegate :support_xml, to: :service, allow_nil: true
  delegate :agreements, to: :service, allow_nil: true
  has_many :service_version_health_checks
  after_save :send_monitor_notifications, if: :availability_status_changed?

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

  enum availability_status: [:unknown, :unavailable, :available]

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    self.spec_file_parse_exception = nil
    @spec_file = spec_file
    self.spec = YAML.safe_load(spec_file.read)
  rescue Psych::SyntaxError => e
    self.spec_file_parse_exception = e
  end

  def spec_file_must_be_parseable
    if self.spec_file_parse_exception
      errors.add(:spec_file, I18n.t(:notyamlenorjson))
    end
  end

  def to_param
    version_number.to_s
  end

  def set_version_number
    self.version_number = service.last_version_number + 1
  end

  def update_search_metadata
    service.update_search_metadata if current?
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
    org = Organization.where(dipres_id: ENV['MINSEGPRES_DIPRES_ID'])
    if version_number == 1
      message = I18n.t(:create_new_service_notification, name: name)
    else
      message = I18n.t(:create_new_version_notification, name: name, version: version_number.to_s, changes: changelog)
    end
    Role.where(name: "Service Provider", organization: org).each do |role|
      role.user.notifications.create(subject: self,
        message: message, email: role.email
      )
    end
  end

  def create_state_change_notification(status)
    email = user.roles.where(organization: organization, name: "Service Provider").first.email
    user.notifications.create(subject: self,
      message: I18n.t(:create_state_change_notification, name: name,
        version: self.version_number.to_s, status: status), email: email
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
    return nil unless spec_with_resolved_refs['definition']['paths'].has_key?(path)
    spec_with_resolved_refs['definition']['paths'][path][verb]
  end

  def path(path)
    spec_with_resolved_refs['definition']['paths'][path]
  end

  def path_parameters(path, location = nil)
    _filter_by_location(
      _with_original_index(
        self.path(path)['parameters'] || []
      ),
      location
    )
  end

  def operation_parameters(verb, path, location = nil)
    _filter_by_location(
      _with_original_index(
        operation(verb, path)['parameters'] || []
      ),
      location
    )
  end

  def has_parameters?(verb, path, location = nil)
    path_parameters(path, location).any? ||
      operation_parameters(verb, path, location).any?
  end

  def parameter_locations(verb, path)
    params = (
      (operation(verb, path)['parameters'] || []) +
      (self.path(path)['parameters'] || [])
    )
    order = {'path' => 1, 'query' => 2, 'header' => 3, 'body' => 4}
    params.map{ |p| p['in'] }.uniq.sort_by {|loc| order[loc] || 100}
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
          "--api-package", name,
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

  def _filter_by_location(indexed_params, location = nil )
    if location.nil?
      indexed_params
    else
      indexed_params.select {|i, p| p['in'] == location }
    end
  end

  def _with_original_index(params)
    indexed_params = {}
    params.each_with_index do |p, i|
      indexed_params[i] = p
    end
    indexed_params
  end

  def has_previous_version?
    return !previous_version.nil?
  end

  def previous_version
    self.service.service_versions.where(version_number: self.version_number - 1).take
  end

  def has_next_version?
    return !next_version.nil?
  end

  def next_version
    self.service.service_versions.where(version_number: self.version_number + 1).take
  end

  def base_url
    schemes.first + '://' + host + base_path
  end

  def url_mock
    ENV['URL_MOCK_SERVICE']
  end

  def base_url_mock
    url_mock + mock_auth_type + url + base_path
  end

  def mock_auth_type
    "/"+(service.public? ? 'public' : 'private' )
  end

  def base_url_mock_custom
    custom_mock_service + base_path
  end

  def schemes
    self.spec_with_resolved_refs['definition']['schemes'] || ['http']
  end

  def host
    self.spec_with_resolved_refs['definition']['host'] || 'example.org'
  end

  def base_path
    self.spec_with_resolved_refs['definition']['basePath'] || ''
  end

  def url_destination(destination)
    case destination
    when "real"
      final_url = base_url
    when "mock"
      final_url = base_url_mock
    when "mock_custom"
      unless custom_mock_service.blank?
        final_url = base_url_mock_custom
      else
        final_url = base_url
      end
    else
      final_url = base_url
    end
    final_url
  end

  def invoke(options = {})
    verb = options.fetch(:verb)
    path = options.fetch(:path)
    path_params = options.fetch(:path_params)
    query_params = options.fetch(:query_params)
    header_params = options.fetch(:header_params)
    raw_body = options.fetch(:raw_body)
    destination = options.fetch(:destination, 'real')

    operation = self.operation(verb, path)
    if operation.nil?
      raise ArgumentError,
        "Operation #{verb} #{path} doesn't exist for #{name} r#{version_number}"
    end
    begin
      RestClient::Request.execute(
        method: verb,
        url: url_destination(destination)  + _resolve_path(path, path_params),
        # TODO: Create RestClient::ParamsArray for arrays in query_params or they will be mangled with the [] suffix
        #       and also pre-process arrays in headers, somehow (they aren't handled by restclient)
        headers: header_params.merge(params: query_params),
        payload: raw_body
      )
    rescue RestClient::Exception => e
      e.response
    end
  end

  def _resolve_path(original_path, path_params)
    resolved_path = original_path.dup
    path_params.each do |name, value|
      resolved_path.gsub!("{#{name}}", URI.escape(value.to_s))
    end
    resolved_path
  end

  def monitor_url
    base_url + '/monitor'
  end

  def health_check_response
    RestClient.get(monitor_url)
  rescue RestClient::Exception => e
    e.response
  end

  def perform_health_check!
    response = health_check_response
    plain_body = response.body
    json_body = JSON.parse(plain_body) rescue nil
    if json_body
      required_keys = %w(codigo_estado msj_estado desc_personalizada_estado)
      if required_keys.all? { |k| json_body.has_key?(k) }
        service_version_health_checks.create!(
          http_status: response.code,
          http_response: plain_body,
          status_code: json_body['codigo_estado'],
          status_message: json_body['msj_estado'],
          custom_status_message: json_body['desc_personalizada_estado'],
        )
      else
        service_version_health_checks.create!(
          http_status: response.code,
          http_response: plain_body,
          status_code: -1,
          status_message: "Respuesta en formato incorrecto: #{plain_body.inspect}",
        )
      end
    else
      service_version_health_checks.create!(
        http_status: response.code,
        http_response: plain_body,
        status_code: -1,
        status_message: "Not a JSON response: #{plain_body.inspect}"
      )
    end
  rescue Errno::ECONNREFUSED => e
    service_version_health_checks.create!(
      http_status: -1,
      status_code: -1,
      status_message: "Connection refused. Exception: #{e.inspect}"
    )
  rescue SocketError => e
    service_version_health_checks.create!(
      http_status: -1,
      status_code: -1,
      status_message: "Socket Error. Exception: #{e.inspect}"
    )
  end

  def scheduled_health_check_job_name
    "#{organization.name} / #{name} r#{version_number}"
  end

  # Should return the health check frequency using cron syntax
  def scheduled_health_check_frequency
    frecuency = 1
    frecuency = organization.monitor_param.health_check_frequency if
      organization.has_monitor_params?
    "*/#{frecuency} * * * *"
  end

  # After How much time *without* a positive health check we mark the service
  # version as unavailable
  def unavailable_threshold
    if organization.has_monitor_params?
      organization.monitor_param.unavailable_threshold.minutes
    else
      3.minutes
    end
  end

  def scheduled_health_check_job
    Sidekiq::Cron::Job.find(scheduled_health_check_job_name)
  end

  def monitoring_enabled?
    service.monitoring_enabled?
  end

  def schedule_health_checks
    if current? && monitoring_enabled?
      unless scheduled_health_check_job.present?
        created = Sidekiq::Cron::Job.create(
          name: scheduled_health_check_job_name,
          cron: scheduled_health_check_frequency,
          class: 'ServiceVersionMonitorWorker',
          args: [self.id]
        )
        unless created
          Rails.logger.error "Can't schedule health check monitor for service version id #{self.id}"
        end
      end
    else
      stop_health_checks
    end
  end

  def stop_health_checks
    scheduled_health_check_job&.destroy
  end

  def reschedule_health_checks
    stop_health_checks
    schedule_health_checks
  end

  def update_availability_status
    update_attribute(:availability_status, recalculate_availability_status)
  end

  def recalculate_availability_status
    return :unknown unless monitoring_enabled?
    return :unknown unless last_check
    threshold_time = unavailable_threshold.ago
    checks_in_range = last_check.created_at > threshold_time
    return :unknown unless checks_in_range
    last_healthy_check = service_version_health_checks.where(healthy: true).last
    return :unavailable unless last_healthy_check
    healthy_checks_in_range = last_healthy_check.created_at > threshold_time
    return :unavailable unless healthy_checks_in_range
    return :available
  end

  def last_check
    service_version_health_checks.last
  end

  def send_owner_monitor_notifications(message)
    return if organization == Organization.where(dipres_id: ENV['MINSEGPRES_DIPRES_ID']).first

    owner_role = user.roles.where(organization: organization, name: "Monitor").first
    if owner_role.present?
      email = owner_role.email
      user.notifications.create(subject: self,
        message: message,
          email: email
      )
    end
  end

  def send_gobdigital_monitor_notifications(message)
    org = Organization.where(dipres_id: ENV['MINSEGPRES_DIPRES_ID'])

    Role.where(name: "Monitor", organization: org).each do |role|
      role.user.notifications.create(subject: self,
        message: message, email: role.email
      )
    end
  end

  def send_consumer_organization_monitor_notifications(consumer_organization, message)

    Role.get_organization_users(consumer_organization, "Monitor").each do |user|
      notify_user = User.where(name: user[:name]).first
      unless notify_user.nil?
        notify_user.notifications.create(subject: self,
          message: message, email: user[:email]
        )
      end
    end

  end


  def send_monitor_notifications
    message = I18n.t(:create_service_status_notification, name: name, old: I18n.t(availability_status_was.to_sym), new: I18n.t(availability_status.to_sym))
    send_owner_monitor_notifications(message)
    send_gobdigital_monitor_notifications(message)
    agreements.each do |agreement|
      if agreement.signed?
        send_consumer_organization_monitor_notifications(agreement.service_consumer_organization, message)
      end
    end
  end

end
