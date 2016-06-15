require 'test_helper'

class ServiceTest < ActiveSupport::TestCase

  def create_valid_service!
    service = Service.create!(
      organization: organizations(:segpres),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC)
    )
    service.create_first_version(users(:perico))
    service
  end

  test '#last_version returns the version number of the last service version' do
    service = create_valid_service!
    assert_equal 1, service.last_version_number
    # VALID_SPEC is loaded by test_helper
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico))
    assert_equal 2, service.last_version_number
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico))
    assert_equal 3, service.last_version_number
  end

  test "#can_be_updated_by? returns true for a user who belongs to the service's organization" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:segpres), name: "Whatever")
    assert service.can_be_updated_by?(perico)
  end

  test "#can_be_updated_by? returns false for a user who does not belong to the service's organization" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not service.can_be_updated_by?(perico)
  end

  test '#text_search_vectors returns a vector for searching on the name field' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new('test-service', 'A')
  end

  test '#text_search_vectors returns a vector for searching on the spec title' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new('Swagger Test', 'A')
  end

  test '#text_search_vectors works if there is no info description in the spec file' do
    service = create_valid_service!
    service.last_version.spec['info']['description'] = nil
    service.save!
    assert_nothing_raised { service.text_search_vectors }
  end

  test '#text_search_vectors returns a vector for searching on the spec description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("A short test description", 'B')
  end

  test '#text_search_vectors returns a vector for searching on an operation description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("Gets `Person` objects.\nOptional query param of **size** determines\nsize of returned array\n", 'C')
  end

  test '#text_search_vectors returns a vector for searching on an parameter name' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("size", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an parameter description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("Size of array", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an response description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("Successful response", 'C')
  end

  test '#text_search_vectors returns a vector for searching on an schema title' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("ArrayOfPersons", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an schema description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("Some description for this array", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an property description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Service::SearchVector.new("this is a property description", 'D')
  end
end
