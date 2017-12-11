require 'test_helper'

class TraceabilityControllerTest < ActionDispatch::IntegrationTest
  
  before :each do
    @original_trazabilidad_secret = ENV['TRAZABILIDAD_SECRET']
    ENV['TRAZABILIDAD_SECRET'] = 'somesecret'
    Service.create!(
      name: "SimpleService2",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end
  end

  def teardown
    ENV['TRAZABILIDAD_SECRET'] = @original_trazabilidad_secret
  end

  test 'should get a list of services and urls' do
    get trazabilidad_path, params: { secret: ENV['TRAZABILIDAD_SECRET'] }
    body = JSON.parse(response.body)
    assert body.has_key? 'services'
    assert body['services'].is_a? Array
    test_url = "https://simple-service-interop.herokuapp.com/simple_example"
    assert body['services'].map {|info| info['url'] }.include? test_url
  end
end