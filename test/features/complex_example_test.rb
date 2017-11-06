require "test_helper"
require 'yaml'

class ComplexExampleTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "complex service" do
    skip("Skiped because use external rest service")
    swagger = YAML.load_file("#{Rails.root}/test/files/sample-services/ComplexExample.yaml")
    url_complex_example = swagger['host']+swagger['basePath']+swagger['paths'].keys.first
    visit "#{swagger['schemes'].first}://#{url_complex_example}"
    assert_content 'pedro@dominio.com'
    assert_content 'Juan Andres'
    assert_content 'Perez Cortez'    
  end

end
