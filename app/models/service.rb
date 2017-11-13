class Service < ApplicationRecord
  include Searchable
  belongs_to :organization
  has_and_belongs_to_many :agreements
  has_many :service_versions
  validates :name, uniqueness: true, presence: true
  before_save :update_humanized_name
  before_save :generate_provider_credentials
  validates :spec, swagger_spec: true, presence: true , :on => :create
  validate :spec_file_must_be_parseable
  delegate :description, to: :current_or_last_version
  attr_accessor :spec, :backwards_compatible
  attr_accessor :spec_file_parse_exception

  def spec_file_must_be_parseable
    if self.spec_file_parse_exception
      errors.add(:spec_file, I18n.t(:notyamlenorjson))
    end
  end

  scope :featured, -> { where(featured: true) }
  scope :popular, -> { last(8) } # To be replaced by actual popular services once we have agreements in place
  scope :unavailable, -> { first(0) } # To be replaced by services which are experiencing downtime now
  scope :without_monitoring, -> { first(0) } # To be replaced by services which have monitoring disabled
  scope :without_approved_versions, -> {
    where.not(id: ServiceVersion.current.select(:service_id))
  }

  def generate_provider_credentials
    unless self.public
      self.provider_id ||= self.url
      self.provider_secret ||= SecureRandom.urlsafe_base64
    end
  end

  def generate_client_token
    return nil if provider_secret.nil?
    claims = {
      iss: self.url,
      sub: self.organization.url,
      aud: [self.provider_id],
      exp: client_token_expiration_in_seconds.seconds.from_now
    }
    JSON::JWT.new(claims).sign(self.provider_secret, :HS256).to_s
  end

  def client_token_expiration_in_seconds
    expiration = ENV['PROVIDER_CLIENT_TOKEN_EXPIRATION_IN_SECONDS']
    expiration = expiration.to_i unless expiration.nil?
    expiration = 86400 if expiration.nil? || expiration == 0
    expiration
  end

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

  def to_param
    name
  end

  def create_first_version(user)
    version = service_versions.create(spec: self.spec, user: user,
      backwards_compatible: true)
  end

  def last_version_number
    service_versions.maximum(:version_number) || 0
  end

  def can_be_updated_by?(user)
    !user.nil? && user.roles.where(organization_id: organization.id).exists?(name: "Service Provider")
  end

  def last_version
    service_versions.order('version_number desc').first
  end

  def current_version
    service_versions.where(status: ServiceVersion.statuses[:current]).first
  end

  def current_or_last_version
    current_version || last_version
  end

  # Required by Searchable to (re)build its index
  def text_search_vectors
    vectors = [
      Searchable::SearchVector.new(name, 'A'),
      Searchable::SearchVector.new(humanized_name, 'A'),
      Searchable::SearchVector.new(organization.name, 'B'),
      Searchable::SearchVector.new(organization.initials, 'B')
    ]
    version = current_version || last_version
    unless version.nil?
      vectors.concat(spec_search_vector_extractor.search_vectors(
        version.spec
      ))
    end
    vectors
  end

  def spec_search_vector_extractor
    keys_to_search_for = %w(title description name)
    weight_by_path_pattern = {
      /^info > title$/ => 'A',
      /^info > description$/ => 'B',
      /^paths > [^>]* > [^>]* > description$/ => 'C',
      /^paths > [^>]* > [^>]* > responses > [^>]* > description$/ => 'C',
      /^.*$/ => 'D'
    }
    HashSearchVectorExtractor.new(keys_to_search_for, weight_by_path_pattern)
  end

  def update_humanized_name
    self.humanized_name = self.name.underscore.humanize
  end

  def needs_agreement_to_be_used_by?(user)
    return false if self.public # Public services don't need agreements
    return true if user.nil? # Logged out users can't access non-public services
    return false if user.organizations.include?(self.organization) # Users can access services inside their own orgs
    return false if user.organizations_with_agreement?(self) # TODO: Is it OK to return false if a not-yet-signed agreement exists?
    return true
  end

  def url
    Rails.application.routes.url_helpers.organization_service_path(self.organization, self)
  end
end
