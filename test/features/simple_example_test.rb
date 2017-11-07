require "test_helper"
require 'yaml'

class SimpleExampleTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "hello" do
    skip("Skiped because use external rest service")
    swagger = YAML.load_file("#{Rails.root}/test/files/sample-services/hello.yaml")
    url_simple_example = swagger['host']+swagger['basePath']+swagger['paths'].keys.first
    visit "#{swagger['schemes'].first}://#{url_simple_example}?name=Mundo"
    assert_content 'Hola Mundo'
  end

end
