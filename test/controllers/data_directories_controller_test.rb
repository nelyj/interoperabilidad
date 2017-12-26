require "test_helper"
class DataCategoriesControllerTest < ActionDispatch::IntegrationTest
  
  test 'gets index' do
    get data_directories_path
    assert_equal 200, response.status
  end

end

