require 'test_helper'

class DataCategoriesControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  before :each do
    login_as users(:pedro), scope: :user
  end

  def teardown
    Warden.test_reset!
  end

  test 'should render index' do
    get data_categories_path
    assert_equal response.status, 200
  end

  test 'should create a new data category' do
    assert_difference 'DataCategory.count', 1 do
      post data_categories_path, params: { data_category: { name: 'this is a tag' }}
    end
    assert DataCategory.find_by(name: 'this is a tag')
  end

  test 'should modify a data category' do
    to_be_modified_id = DataCategory.all.first.id
    patch data_category_path(id: to_be_modified_id, data_category: { name: 'whatever else'})
    assert_equal response.status, 302 # Redirected to index
    assert_equal DataCategory.find(to_be_modified_id).name, 'whatever else'
  end

  test 'should delete a data category' do
    assert_difference 'DataCategory.count', -1 do
      to_be_deleted_id = DataCategory.all.first.id
      delete data_category_path({ id: to_be_deleted_id })
    end
    assert_equal response.status, 302 # Redirected to index
  end

  test 'index should redirect in case the user is not logged in' do
    Warden.test_reset!
    get data_categories_path
    assert_equal 302, response.status
  end

  test "should not create data categories if user isn't logged in" do
    Warden.test_reset!
    assert_no_difference 'DataCategory.count' do
      post data_categories_path, params: { data_category: { name: 'this is a tag' }}
    end
    assert_equal 302, response.status
  end

  test "should not update data categories if user isn't logged in" do
    Warden.test_reset!
    to_be_modified_id = DataCategory.all.first.id
    patch data_category_path(id: to_be_modified_id, data_category: { name: 'whatever else'})
    assert_equal response.status, 302 # Redirected to index
    assert_not_equal DataCategory.find(to_be_modified_id).name, 'whatever else'
  end

  test "should not delete data categories if user isn't logged in" do
    Warden.test_reset!
    assert_no_difference 'DataCategory.count' do
      to_be_deleted_id = DataCategory.all.first.id
      delete data_category_path({ id: to_be_deleted_id })
    end
  end
end