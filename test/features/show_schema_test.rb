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

   test "Schema Version show previous versions" do
     schema_version = schema_versions(:rut_v3)
     previous_version = schema_version.previous_version
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'a.btn.btn-tiny-rounded.blue', text: 'V' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description
     end
     click_link ("Versión Anterior")
     within ".container-schema-detail" do
       assert_selector 'h1', text: previous_version.schema.name
       assert_selector 'a.btn.btn-tiny-rounded.blue', text: 'V' + previous_version.version_number.to_s
       assert_selector 'p', text: previous_version.description
     end
   end

   test "Schema Version show next versions" do
     schema_version = schema_versions(:rut_v2)
     next_version = schema_version.next_version
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'a.btn.btn-tiny-rounded.blue', text: 'V' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description
     end
     click_link ("Versión Siguiente")
     within ".container-schema-detail" do
       assert_selector 'h1', text: next_version.schema.name
       assert_selector 'a.btn.btn-tiny-rounded.blue', text: 'V' + next_version.version_number.to_s
       assert_selector 'p', text: next_version.description
     end
   end

   test "Schema Version show History" do
     schema_version = schema_versions(:rut_v2)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     click_link ("Historial")
     within ".container.container.new-schemas-container" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'h4', text: schema_version.schema.schema_category.name
       assert_text schema_version.previous_version.version_number
       assert_text schema_version.previous_version.created_at.to_s
       assert_text schema_version.previous_version.user.name
       assert_text schema_version.version_number
       assert_text schema_version.created_at.to_s
       assert_text schema_version.user.name
       assert_text schema_version.next_version.version_number
       assert_text schema_version.next_version.created_at.to_s
       assert_text schema_version.next_version.user.name
     end
   end

end
