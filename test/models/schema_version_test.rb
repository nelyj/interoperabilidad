require 'test_helper'

class SchemaVersionTest < ActiveSupport::TestCase

  test 'validations' do
    # VALID_SCHEMA_OBJECT and INVALID_SCHEMA_OBJECT are loaded by test_helper
    valid_schema_version = SchemaVersion.new(
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT), schema: schemas(:rut),
      user: users(:pablito))
    invalid_schema_version = SchemaVersion.new(
      spec_file: StringIO.new(INVALID_SCHEMA_OBJECT), schema: schemas(:rut),
      user: users(:pablito))
    assert valid_schema_version.valid?
    assert_not invalid_schema_version.valid?
    assert_not invalid_schema_version.errors[:spec].blank?
  end

  test 'spec_with_resolved_refs is stored automatically when saving' do
    valid_schema_version = SchemaVersion.new(
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT), schema: schemas(:rut),
      user: users(:pablito)
    )
    valid_schema_version.save!
    assert valid_schema_version.spec_with_resolved_refs.has_key?('definition')
    assert valid_schema_version.spec_with_resolved_refs.has_key?('references')
  end
end
