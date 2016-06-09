require 'test_helper'

class SchemaVersionTest < ActiveSupport::TestCase

  test 'validations' do
    # VALID_SCHEMA_OBJECT and INVALID_SCHEMA_OBJECT are loaded by test_helper
    valid_schema_version = SchemaVersion.new(
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT), schema: schemas(:rut))
    invalid_schema_version = SchemaVersion.new(
      spec_file: StringIO.new(INVALID_SCHEMA_OBJECT), schema: schemas(:rut))
    assert valid_schema_version.valid?
    assert_not invalid_schema_version.valid?
    assert_not invalid_schema_version.errors[:spec].blank?
  end
end
