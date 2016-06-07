require 'test_helper'

class SchemaTest < ActiveSupport::TestCase

  test '#last_version returns the version number of the last schema version' do
    schema = Schema.create(
      schema_category: schema_categories(:informacion_de_personas),
      name: 'test-schema',
      spec: VALID_SCHEMA_OBJECT
    )
    assert_equal 1, schema.last_version_number
    # VALID_SCHEMA_OBJECT is loaded by test_helper
    schema.schema_versions.create(spec: VALID_SCHEMA_OBJECT)
    assert_equal 2, schema.last_version_number
    schema.schema_versions.create(spec: VALID_SCHEMA_OBJECT)
    assert_equal 3, schema.last_version_number
  end
end
