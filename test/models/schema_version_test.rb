require 'test_helper'

VALID_SCHEMA_OBJECT = '{
  "type": "object",
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string"
    },
    "age": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  }
}'

INVALID_SCHEMA_OBJECT = '{
  "type": "object",
  "required": [
    "name"
  ],
  "properties": {
    "address": {
      "$ref": "#/definitions/Address"
    },
    "age": {
      "type": "integer",
      "format": "int32",
      "minimum": 0
    }
  }
}'

class SchemaVersionTest < ActiveSupport::TestCase
  test 'validations' do
    valid_schema_version = SchemaVersion.new(
      spec: VALID_SCHEMA_OBJECT, schema: schemas(:rut))
    invalid_schema_version = SchemaVersion.new(
      spec: INVALID_SCHEMA_OBJECT, schema: schemas(:rut))
    assert valid_schema_version.valid?
    assert_not invalid_schema_version.valid?
    assert_not invalid_schema_version.errors[:spec].blank?
  end
end
