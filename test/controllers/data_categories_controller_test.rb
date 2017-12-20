require 'test_helper'

class DataCategoriesControllerTest < ActionDispatch::IntegrationTest

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
end