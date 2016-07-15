require "test_helper"

class ShowSchemaTest < Capybara::Rails::TestCase

   test "Schema Version Name description version url next and previous versions history and spec" do
     schema_version = schema_versions(:rut_v2)
     visit schema_schema_version_path(schema_version.schema, schema_version)

     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'a.btn.btn-tiny.blue', text: 'R' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description

       within '.url-canonica' do
         assert_content schema_schema_version_path(schema_version.schema, schema_version, format: :json)
       end

       within '.history-version' do
         assert find_link('Versión anterior')
         assert find_link('Versión siguiente')
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
         assert find_link('Versión siguiente')
       end
     end
   end

   test "Schema Version does not have next_version" do
     schema_version = schema_versions(:rut_v3)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       within '.history-version' do
         assert find_link('Versión anterior')
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
       assert_selector 'a.btn.btn-tiny.blue', text: 'R' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description
     end
     click_link ("Versión anterior")
     within ".container-schema-detail" do
       assert_selector 'h1', text: previous_version.schema.name
       assert_selector 'a.btn.btn-tiny.blue', text: 'R' + previous_version.version_number.to_s
       assert_selector 'p', text: previous_version.description
     end
   end

   test "Schema Version show next versions" do
     schema_version = schema_versions(:rut_v2)
     next_version = schema_version.next_version
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'a.btn.btn-tiny.blue', text: 'R' + schema_version.version_number.to_s
       assert_selector 'p', text: schema_version.description
     end
     click_link ("Versión siguiente")
     within ".container-schema-detail" do
       assert_selector 'h1', text: next_version.schema.name
       assert_selector 'a.btn.btn-tiny.blue', text: 'R' + next_version.version_number.to_s
       assert_selector 'p', text: next_version.description
     end
   end

   test "Schema Version show History" do
     schema_version = schema_versions(:rut_v2)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     click_link ("Historial")
     within ".container.new-schemas-container" do
       assert_selector 'h1', text: schema_version.schema.name
       assert_selector 'h4', text: "Información de Personas"
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

   test "Schema Version show Schemas In the Same Category" do
     schema_version = schema_versions(:zona1_v1)
     visit schema_schema_version_path(schema_version.schema, schema_version)
     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
     end

     within ".list-categories" do
       assert_selector "li", text: schema_version.schema.name
       assert_link schema_version.schema.name
       assert_link schemas(:zona2).name
       assert_link schemas(:zona3).name
       assert_link schemas(:zona4).name
       click_link schemas(:zona3).name
     end
     schema_version = schema_versions(:zona3_v1)
     within ".container-schema-detail" do
       assert_selector 'h1', text: schema_version.schema.name
     end

     within ".list-categories" do
       assert_selector "li", text: schema_version.schema.name
       assert_link schema_version.schema.name
       assert_link schemas(:zona2).name
       assert_link schemas(:zona1).name
       assert_link schemas(:zona4).name
     end
   end
end
