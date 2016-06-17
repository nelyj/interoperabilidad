require 'test_helper'

class SchemaTest < ActiveSupport::TestCase

  test '#last_version returns the version number of the last schema version' do
    # VALID_SCHEMA_OBJECT is loaded by test_helper
    schema = Schema.create(
      schema_category: schema_categories(:informacion_de_personas),
      name: 'test-schema',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT)
    )
    assert_equal 1, schema.last_version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT))
    assert_equal 2, schema.last_version_number
    schema.schema_versions.create(spec_file: StringIO.new(VALID_SCHEMA_OBJECT))
    assert_equal 3, schema.last_version_number
  end

  test 'validations' do
    # VALID_SCHEMA_OBJECT and INVALID_SCHEMA_OBJECT are loaded by test_helper
    valid_schema = Schema.new(
      name: 'test',
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT),
      schema_category: schema_categories(:informacion_de_personas)
    )
    invalid_schema = Schema.new(
      name: 'test2',
      spec_file: StringIO.new(INVALID_SCHEMA_OBJECT),
      schema_category: schema_categories(:informacion_de_personas)
    )
    assert valid_schema.valid?
    assert_not invalid_schema.valid?
    assert_not invalid_schema.errors[:spec].blank?
  end

  test '#last_version returns the latest schema version' do
    # TODO
  end

  test "#description returns the description inside the latest schema version's spec" do
  end

  test "#description returns nil if the latest schema version's spec is not present" do
  end


end
