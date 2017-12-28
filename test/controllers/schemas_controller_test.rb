require 'test_helper'
require_relative '../features/support/agreement_creation_helper'

class SchemasControllerTest < ActionDispatch::IntegrationTest
  include AgreementCreationHelper

  test "get 404 on wrong schema name in URL" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get schema_schema_version_path(schema_name: "SchemaWrongName", version_number: 1)
      assert_response 404
    end
  end

  test "get 404 on wrong schema version in URL" do
    schema = create_valid_schema!
    get schema_schema_version_path(schema_name: schema.name, version_number: 1)
    assert_response 200
    assert_raises(ActiveRecord::RecordNotFound) do
      get schema_schema_version_path(schema_name: schema.name, version_number: 99)
      assert_response 404
    end
  end

end
