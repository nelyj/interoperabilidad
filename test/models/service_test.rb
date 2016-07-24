require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
# VALID_SCHEMA_OBJECT and INVALID_SCHEMA_OBJECT are loaded by test_helper
  def create_valid_service!
    service = Service.create!(
      organization: organizations(:segpres),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:perico))
    service
  end

  test '#search returns services based on an existing text' do
    valid_service = create_valid_service!
    service = Service.create!(
      organization: organizations(:segpres),
      name: 'Datos',
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:perico))
    assert_equal service, Service.search("Datos").first
  end

  test '#search returns no services based on non existing text' do
    valid_service = create_valid_service!
    assert Service.search("Datos").blank?
  end

  test '#spec validation is correct' do
    valid_service = create_valid_service!
    assert valid_service.valid?
  end

  test '#spec validation returns errors' do
    invalid_service = Service.new(
      organization: organizations(:segpres),
      name: 'test-service2',
      spec_file: StringIO.new(INVALID_SPEC)
    )
    assert_not invalid_service.valid?
    assert_not invalid_service.errors[:spec].blank?
  end

  test '#last_version returns the version number of the last service version' do
    service = create_valid_service!
    assert_equal 1, service.last_version_number
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico), backwards_compatible: true)
    assert_equal 2, service.last_version_number
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico), backwards_compatible: true)
    assert_equal 3, service.last_version_number
  end

  test "#can_be_updated_by? returns false if user is nil" do
    assert_not create_valid_service!.can_be_updated_by?(nil)
  end

  test "#can_be_updated_by? returns true for a user who belongs to the service's organization and is a Service Provider" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:segpres), name: "Service Provider")
    assert service.can_be_updated_by?(perico)
  end

  test "#can_be_updated_by? returns false for a user who belongs to the service's organization and is not a Service Provider" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:segpres), name: "Whatever")
    assert_not service.can_be_updated_by?(perico)
  end

  test "#can_be_updated_by? returns false for a user who does not belong to the service's organization" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not service.can_be_updated_by?(perico)
  end

  test "#can_be_updated_by? returns false for a user who does not belong to the service's organization and is a Service Provider" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Service Provider")
    assert_not service.can_be_updated_by?(perico)
  end

  test '#text_search_vectors returns a vector for searching on the name field' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new('test-service', 'A')
  end

  test '#text_search_vectors returns a vector for searching on the spec title' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new('Swagger Test', 'A')
  end

  test '#text_search_vectors works if there is no info description in the spec file' do
    service = create_valid_service!
    service.last_version.spec['info']['description'] = nil
    service.save!
    assert_nothing_raised { service.text_search_vectors }
  end

  test '#text_search_vectors returns a vector for searching on the spec description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("A short test description", 'B')
  end

  test '#text_search_vectors returns a vector for searching on an operation description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("Gets `Person` objects.\nOptional query param of **size** determines\nsize of returned array\n", 'C')
  end

  test '#text_search_vectors returns a vector for searching on an parameter name' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("size", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an parameter description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("Size of array", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an response description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("Successful response", 'C')
  end

  test '#text_search_vectors returns a vector for searching on an schema title' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("ArrayOfPersons", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an schema description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("Some description for this array", 'D')
  end

  test '#text_search_vectors returns a vector for searching on an property description' do
    service = create_valid_service!
    assert_includes service.text_search_vectors, Searchable::SearchVector.new("this is a property description", 'D')
  end
end
