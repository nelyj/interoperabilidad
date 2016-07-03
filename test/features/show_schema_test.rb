require "test_helper"

class ShowSchemaTest < Capybara::Rails::TestCase

   test "Schema Category Name and Description" do
     schema_version = schema_versions(:rut_v1)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".box-detail-header" do
       assert_selector 'h2', text: schema_version.schema.schema_category.name
       assert_selector 'p', text: schema_version.schema.schema_category.description
     end
   end

   test "Schema Version Name description version url next and previous versions history and spec" do
     schema_version = schema_versions(:rut_v2)
     visit schema_schema_version_path(schema_version.schema, schema_version)

     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'a.btn.btn-tiny-rounded.blue', text: 'V' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description

       within '.url-canonica' do
         assert_content schema_schema_version_path(schema_version.schema, schema_version, format: :json)
       end

       within '.history-version' do
         assert find_link('Versión Anterior')
         assert find_link('Versión Siguiente')
         assert find_link('Historial')
       end

       within '.schema-panel-set.detail' do
         assert_selector 'h3', text: schema_version.schema.name
       end
     end
   end

   test "Schema Version OAS and new version buttons and example" do
     schema_version = schema_versions(:rut_v2)
     visit schema_schema_version_path(schema_version.schema, schema_version)

     within ".container-schema-action" do
       assert find_link('Ver OAS')
       within ".box-code-example" do
         assert_text "Sin ejemplo."
       end
     end
   end

   test "Schema Version does not have previous_version" do
     schema_version = schema_versions(:rut_v1)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       within '.history-version' do
         assert_text 'VERSIÓN ANTERIOR'
         assert find_link('Versión Siguiente')
       end
     end
   end

   test "Schema Version does not have next_version" do
     schema_version = schema_versions(:rut_v3)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       within '.history-version' do
         assert find_link('Versión Anterior')
         assert_text 'VERSIÓN SIGUIENTE'
       end
     end
   end

end
