class Service < ApplicationRecord
  include Searchable
  belongs_to :organization
  has_and_belongs_to_many :agreement_revisions
  has_many :service_versions
  validates :name, uniqueness: true, presence: true
  before_save :update_humanized_name
  validates :spec, swagger_spec: true
  delegate :description, to: :current_or_last_version
  attr_accessor :spec, :backwards_compatible
  attr_accessor :spec_file_parse_exception

  def spec_file_must_be_parseable
    if self.spec_file_parse_exception
      errors.add(:spec_file, "Archivo no está en formato JSON o YAML")
    end
  end

  scope :featured, -> { where(featured: true) }
  scope :popular, -> { last(8) } # To be replaced by actual popular services once we have agreements in place

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
    user.roles.where(organization_id: organization.id).exists?(name: "Service Provider")
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
end
