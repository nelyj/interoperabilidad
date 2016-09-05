require './lib/role_service.rb'
require './lib/signer.rb'

class Agreement <ApplicationRecord
  belongs_to :service_provider_organization, :class_name => 'Organization'
  belongs_to :service_consumer_organization, :class_name => 'Organization'
  has_many :organizations
  has_many :agreement_revisions, -> { order('revision_number DESC') }
  has_and_belongs_to_many :services
  after_create :create_first_revision
  after_create :generate_client_credentials!
  validates :service_provider_organization, presence: true
  validates :services, presence: true
  delegate :state, to: :last_revision
  attr_accessor :purpose, :legal_base, :user, :objection_message

  def create_first_revision
    agreement_revisions.create!(
      purpose: self.purpose,
      user: self.user,
      legal_base: self.legal_base,
      revision_number: 1,
      log: I18n.t(:draft_log)
    )
  end

  def generate_client_credentials!
    self.client_secret ||= SecureRandom.urlsafe_base64
    save!
  end

  def generate_client_token(service)
    return nil unless state == 'signed'
    return nil unless services.include?(service)
    claims = {
      iss: self.url,
      sub: self.service_consumer_organization.url,
      aud: [service.provider_id],
      exp: client_token_expiration_in_seconds.seconds.from_now
    }
    JSON::JWT.new(claims).sign(service.provider_secret, :HS256).to_s
  end

  def client_token_expiration_in_seconds
    expiration = ENV['AGREEMENT_CLIENT_TOKEN_EXPIRATION_IN_SECONDS']
    expiration = expiration.to_i unless expiration.nil?
    expiration = 86400 if expiration.nil? || expiration == 0
    expiration
  end

  def last_revision_number
    agreement_revisions.maximum(:revision_number) || 0
  end

  def last_revision
    agreement_revisions.first
  end

  def new_revision(user,new_state,log,message, file)
    agreement_revisions.create(
      user: user,
      state: new_state,
      purpose: last_revision.purpose,
      legal_base: last_revision.legal_base,
      log: log,
      file: file,
      objection_message: message
    )
  end

  def next_step
    case state
    when 'draft'
      'validated_draft'
    when 'validated_draft'
      'signed_draft'
    when 'objected'
      'draft'
    when 'signed_draft'
      'validated'
    when 'validated'
      'signed'
    when 'rejected_sign'
      'validated'
    else
      ''
    end
  end

  def parse_persons(persons, role, org)
    users = Array.new
    return [{name: "", email: [""]}] if persons.nil?
    persons.map do |p|
      first_name = p["nombre"]["nombres"].join(' ')
      last_name = p["nombre"]["apellidos"].join(' ')
      name = first_name.strip + ' ' + last_name.strip

      emails = Array.new
      last_email = ""
      p["instituciones"].map do |i|
        if i["institucion"]["id"] == org.dipres_id && i["rol"] == role
          emails << i["email"]
        end
      end

      users << {name: name, email: emails}
    end
    users
  end

  def next_step_responsables
    next_role = AgreementRevision.state_to_role(next_step)
    response = RoleService.get_organization_users(active_organization_in_flow, next_role)

    if response.code == 200
      response = JSON.parse(response)
      parse_persons(response["personas"], next_role, active_organization_in_flow )
    else
      Rollbar.error('Call to Role Service for organization: ' + active_organization_in_flow.name +
        ' role: ' + next_role + ' Returned: ' + response.code.to_s)
      return nil
    end
  end

  def active_organization_in_flow
    if %w(draft validated_draft objected).include?(state)
      service_consumer_organization
    else
      service_provider_organization
    end
  end

  def user_can_update_agreement_status?(user)
    role = AgreementRevision.state_to_role(next_step)
    user.roles.where(organization: active_organization_in_flow, name: role).exists?
  end

  def validate_draft(user)
    new_state = AgreementRevision.states['validated_draft']
    #check if user is a prosecutor and state alows the change.
    return nil unless user_can_update_agreement_status?(user) && last_revision.draft?
    new_revision(user,new_state, I18n.t(:validated_draft_log),"", last_revision.file)
  end

  def object_draft(user, message)
    new_state = AgreementRevision.states['objected']
    valid_state = last_revision.validated_draft? || last_revision.signed_draft?
    return nil unless user_can_update_agreement_status?(user) && valid_state
    new_revision(user, new_state, I18n.t(:objected_log), message, last_revision.file)
  end

  def sign_draft(user, otp)
    new_state = AgreementRevision.states['signed_draft']
    return nil unless user_can_update_agreement_status?(user) && last_revision.validated_draft?
    rev = new_revision(user, new_state, I18n.t(:signed_draft_log), "", last_revision.file)
    if sign_pdf(otp)
      rev
    else
      last_revision.delete
      return nil
    end
  end

  def validate_revision(user)
    new_state = AgreementRevision.states['validated']
    return nil unless user_can_update_agreement_status?(user) && (last_revision.signed_draft? || last_revision.rejected_sign?)
    new_revision(user, new_state, I18n.t(:validated_log), "", last_revision.file)
  end

  def sign(user, otp)
    new_state = AgreementRevision.states['signed']
    return nil unless user_can_update_agreement_status?(user) && last_revision.validated?
    rev = new_revision(user, new_state, I18n.t(:signed_log), "", last_revision.file)
    if sign_pdf(otp)
      rev
    else
      last_revision.delete
      return nil
    end
  end

  def reject_sign(user, message)
    new_state = AgreementRevision.states['rejected_sign']
    return nil unless user_can_update_agreement_status?(user) && last_revision.validated?
    new_revision(user, new_state, I18n.t(:rejected_sign_log), message, last_revision.file)
  end

  def download_last_version_pdf (file_path)
    url = last_revision.request_pdf_url
    response = RestClient.get(url)
    if response.code == 200
      file = response.body
      File.open(file_path, 'wb') {|f| f.write(file)}
      return true
    else
      return false
    end
  end

  def sign_pdf(otp)
    file_path = "#{Rails.root}/tmp/"+ last_revision.file
    return  false unless download_last_version_pdf(file_path)
    org = state.include?("signed_draft") ? service_consumer_organization : service_provider_organization
    file = File.read(file_path)

    result = SignerApi.upload_file(file, last_revision.user, org)
    puts result.body
    if result.code == 200
      jresult = JSON.parse(result)
      result = SignerApi.sign_document(jresult["session_token"], otp)
      puts result.body
      if result.code == 200
        jresult = JSON.parse(result)
        return false unless jresult["files"].first["status"] == "OK"
        encodedfile = jresult["files"].first["content"]
        rchecksum = jresult["files"].first["checksum"]
        checksum = Digest::SHA256.hexdigest encodedfile
        return false unless rchecksum.include?(checksum)

        new_file_name = "CID-#{id}-#{last_revision_number}_#{service_provider_organization.initials.upcase}_#{service_consumer_organization.initials.upcase}.pdf"
        new_file_path = "#{Rails.root}/tmp/" + new_file_name

        File.open(new_file_path, 'wb') {|f| f.write(Base64.decode64(encodedfile))}
        last_revision.upload_pdf(new_file_name, new_file_path)
      else
        return false
      end
    else
      return false
    end
    return true
  end

  def url
    Rails.application.routes.url_helpers.organization_agreement_path(self.service_consumer_organization, self)
  end

end
