class Service < ApplicationRecord
  belongs_to :organization
  has_many :service_versions
  validates :name, uniqueness: true
  before_save :update_humanized_name
  after_save :update_search_metadata
  attr_accessor :spec
  validates :spec, swagger_spec: true

  def spec_file
    @spec_file
  end

  def spec_file=(spec_file)
    @spec_file = spec_file
    self.spec = JSON.parse(spec_file.read)
  end

  def self.search_configuration
    if Rails.env.test? # Migrations don't run on test database :(
      "spanish"
    else
      "es"
    end
  end

  def to_param
    name
  end

  def create_first_version(user)
    service_versions.create(spec: self.spec, user: user)
  end

  def last_version_number
    service_versions.maximum(:version_number) || 0
  end

  def can_be_updated_by?(user)
    user.organizations.exists?(id: organization.id)
  end

  def last_version
    service_versions.order('version_number desc').first
  end

  def current_version
    service_versions.where(status: ServiceVersion.statuses[:current]).first
  end

  class SearchVector < Struct.new(:document, :weight)
  end

  def text_search_vectors
    vectors = [SearchVector.new(name, 'A'), SearchVector.new(humanized_name, 'A')]
    version = current_version || last_version
    return vectors if version.nil?
    keys_to_search_for = %w(title description name)
    weight_by_path_pattern = {
      /^info > title$/ => 'A',
      /^info > description$/ => 'B',
      /^paths > [^>]* > [^>]* > description$/ => 'C',
      /^paths > [^>]* > [^>]* > responses > [^>]* > description$/ => 'C',
    } # anything not matched by a pattern but in a search key will get a 'D'
    matches = deep_find_strings(version.spec, keys_to_search_for)
    return vectors + matches.map do |path, text|
      match_weight = 'D' # default
      string_path = path.join(" > ")
      weight_by_path_pattern.each do |pattern, weight|
        if string_path =~ pattern
          match_weight = weight
          break
        end
      end
      SearchVector.new(text, match_weight)
    end
  end

  def deep_find_strings(hash, keys_to_search_for, current_path = nil)
    current_path ||= []
    results = []
    hash.each do |key, value|
      if value.is_a?(String) && keys_to_search_for.include?(key)
        results << [current_path + [key], value]
      elsif value.is_a? Hash
        results.concat(deep_find_strings(
          value, keys_to_search_for, current_path + [key]
        ))
      elsif value.is_a? Array
        value.select{|e| e.is_a?(Hash)}.each do |subhash|
          results.concat(deep_find_strings(
            subhash, keys_to_search_for, current_path + [key]
          ))
        end
      end
    end
    results
  end

  def update_search_metadata
    search_vector_sql = text_search_vectors.map do |search_vector|
      "setweight(to_tsvector(
        #{ActiveRecord::Base.sanitize(Service.search_configuration)},
        #{ActiveRecord::Base.sanitize(search_vector.document)}),
        #{ActiveRecord::Base.sanitize(search_vector.weight)}
      )"
    end.join("||")
    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE services SET lexemes = #{search_vector_sql}
      WHERE services.id = #{ActiveRecord::Base.sanitize(self.id)}
    SQL
  end

  def update_humanized_name
    self.humanized_name = self.name.underscore.humanize
  end

  def self.search(text)
     query = <<-SQL
      SELECT *
      FROM services, plainto_tsquery(?, ?) as search_text
      WHERE (lexemes @@ search_text)
      ORDER BY ts_rank(lexemes, search_text) DESC;
    SQL
    Service.find_by_sql [query, Service.search_configuration, text]
  end
end
