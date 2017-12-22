class Schema < ApplicationRecord
  include Searchable
  has_and_belongs_to_many :schema_categories
  has_many :schema_versions
  has_many :schema_data_categories
  has_many :data_categories, through: :schema_data_categories

  validates :name, uniqueness: true, presence: true
  attr_accessor :spec
  validates :spec, swagger_schema_object: true, presence: true
  before_save :update_humanized_name
  delegate :description, to: :last_version
  validate :spec_file_must_be_parseable
  attr_accessor :spec_file_parse_exception


  def spec_file_must_be_parseable
    if self.spec_file_parse_exception
      errors.add(:spec_file, "Archivo no está en formato JSON o YAML")
    end
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
    schema_versions.create(spec: self.spec, user: user)
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

  def set_data_categories(data_categories_id_params)
    old_category_ids = self.data_categories.pluck(:id)
    new_category_ids = data_categories_id_params
                        .map(&:to_i)
                        .select { |id| id > 0 }

    discarded_categories = old_category_ids - new_category_ids
    added_categories = new_category_ids - old_category_ids

    discarded_categories.each do |data_cat_id|
      # Since each schema_id && data_category_id is unique (as enforced by the UNIQUE constraint)
      # .first is fine
      SchemaDataCategory.where(schema_id: self.id, data_category_id: data_cat_id)
                         .first
                         .destroy
    end

    added_categories.each do |data_cat_id|
      SchemaDataCategory.create!(schema_id: self.id, data_category_id: data_cat_id)
    end
  end
end
