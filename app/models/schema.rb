class Schema < ApplicationRecord
  include Searchable
  belongs_to :schema_category
  has_many :schema_versions

  validates :name, uniqueness: true
  attr_accessor :spec
  validates :spec, swagger_schema_object: true
  after_create :create_first_version
  before_save :update_humanized_name
  delegate :description, to: :last_version

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = YAML.safe_load(spec_file.read)
  end

  def to_param
    name
  end

  def create_first_version
    schema_versions.create(spec: self.spec)
  end

  def last_version_number
    schema_versions.maximum(:version_number) || 0
  end

  def last_version
    schema_versions.order('version_number desc').first
  end

  def update_humanized_name
    self.humanized_name = self.name.underscore.humanize
  end

  # Required by Searchable to (re)build its index
  def text_search_vectors
    vectors = [
      Searchable::SearchVector.new(name, 'A'),
      Searchable::SearchVector.new(humanized_name, 'A')
    ]
    version = last_version
    unless version.nil?
      vectors.concat(spec_search_vector_extractor.search_vectors(
        version.spec
      ))
    end
    vectors
  end

  def spec_search_vector_extractor
    keys_to_search_for = %w(title description)
    weight_by_path_pattern = {
      /^title$/ => 'A',
      /^description$/ => 'B',
      /^properties > [^>]* > description$/ => 'C',
      /^.*$/ => 'D' # Anything else nested inside properties will get lower
                    # weight
    }
    HashSearchVectorExtractor.new(keys_to_search_for, weight_by_path_pattern)
  end
end
