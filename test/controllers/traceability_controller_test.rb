require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  
  before :each do
    @originaL_trazabilidad_secret = ENV['TRAZABILIDAD_SECRET']
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
    ENV['TRAZABILIDAD_SECRET'] = @originaL_trazabilidad_secret
  end

  test 'should get a new token' do
    post trazabilidad_token_path, params: { secret: ENV['TRAZABILIDAD_SECRET'] }
    assert_equal response.status, 200
    body =  JSON.parse(response.body)
    assert body.has_key? "token"
    assert body["token"].is_a? String
  end

  test 'should get a list of services and urls' do
    post trazabilidad_token_path, params: { secret: ENV['TRAZABILIDAD_SECRET'] }
    token = JSON.parse(response.body)['token']
    get trazabilidad_path, params: { token: token }
    body = JSON.parse(response.body)
    assert body.has_key? 'services'
    assert body['services'].is_a? Array
    assert body['services'].map {|info| info['url'] }.include? "https://simple-service-interop.herokuapp.com/simple_example"
  end
end