require 'test_helper'

class SchemaTest < ActiveSupport::TestCase
# VALID_SCHEMA_OBJECT and INVALID_SCHEMA_OBJECT are loaded by test_helper
  def create_valid_schema!
    # Schema automatically creates the first schema_version
    schema = Schema.create(
      schema_categories: [schema_categories(:informacion_de_personas)],
      name: 'test-schema',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
    )
    schema.create_first_version(users(:pablito))
    schema.save
    schema
  end

  test '#search returns schemas based on an existing text' do
    valid_schema = create_valid_schema!
    schema = Schema.create!(
      schema_categories: [schema_categories(:informacion_de_personas)],
      name: 'Persona',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
    )
    schema.create_first_version(users(:pablito))
    assert_equal schema, Schema.search("Persona").first
  end

  test '#search returns no schemas based on non existing text' do
    valid_schema = create_valid_schema!
    assert Schema.search("Patente").blank?
  end

  test '#last_version returns the version number of the last schema version' do
    schema = create_valid_schema!
    assert_equal 1, schema.last_version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT), user: users(:pablito))
    assert_equal 2, schema.last_version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT), user: users(:pablito))
    assert_equal 3, schema.last_version_number
  end

  test '#schema object validation is correct' do
    valid_schema = create_valid_schema!
    assert valid_schema.valid?
  end

  test '#schema object validation returns errors' do
    invalid_schema = Schema.new(
      name: 'test2',
      spec_file: StringIO.new(INVALID_SCHEMA_OBJECT),
      schema_categories: [schema_categories(:informacion_de_personas)]
    )
    assert_not invalid_schema.valid?
    assert_not invalid_schema.errors[:spec].blank?
  end

  test '#last_version returns the latest schema version' do
    schema = create_valid_schema!
    assert_equal 1, schema.last_version.version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT), user: users(:pablito))
    assert_equal 2, schema.last_version.version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT), user: users(:pablito))
    assert_equal 3, schema.last_version.version_number
  end

  test "#description returns the description inside the latest schema version's spec" do
    schema = create_valid_schema!
    assert_equal "Some object", schema.description
    version = schema.schema_versions.build(spec_file: StringIO.new(VALID_SCHEMA_OBJECT), user: users(:pablito))
    version.spec['description'] = "New object"
    version.save!
    assert_equal "New object", schema.description
  end

  test "#description returns nil if the latest schema version's spec is not present" do
    schema = create_valid_schema!
    version = schema.last_version
    version.spec = version.spec.except!('description')
    version.save!
    assert_equal nil, schema.description
  end

  test '#text_search_vectors returns a vector for searching on the name field' do
    schema = create_valid_schema!
    assert_includes schema.text_search_vectors, Searchable::SearchVector.new('test-schema', 'A')
  end

  test '#text_search_vectors returns a vector for searching on the spec title' do
    schema = create_valid_schema!
    assert_includes schema.text_search_vectors, Searchable::SearchVector.new('Valid', 'A')
  end

  test '#text_search_vectors works if there is no info description in the spec file' do
    schema = create_valid_schema!
    schema.last_version.spec['description'] = nil
    schema.save!
    assert_nothing_raised { schema.text_search_vectors }
  end

  test '#text_search_vectors returns a vector for searching on the spec description' do
    schema = create_valid_schema!
    assert_includes schema.text_search_vectors, Searchable::SearchVector.new("Some object", 'B')
  end

  test '#text_search_vectors returns a vector for searching on a property description' do
    schema = create_valid_schema!
    assert_includes schema.text_search_vectors, Searchable::SearchVector.new("Second description", 'C')
  end
end
