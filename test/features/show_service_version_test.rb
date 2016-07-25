require "test_helper"

class ShowServiceTest < Capybara::Rails::TestCase

  test "Service Version does not have previous_version" do
    service_version = service_versions(:servicio1_v1)
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    assert find_link('Versión anterior')[:class].include?('detail-action deactivate')
    assert find_link('Versión siguiente')[:class].include?('detail-action')
  end

  test "Service Version does have next_version" do
    service_version = service_versions(:servicio1_v2)
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    assert find_link('Versión anterior')[:class].include?('detail-action')
    assert find_link('Versión siguiente')[:class].include?('detail-action')
  end

  test "Service Version show previous versions" do
    service_version = service_versions(:servicio1_v3)
    previous_version = service_version.previous_version
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    titles = find_all(".title")
    within titles[0] do
      assert_selector 'h1', text: service_version.name + ' R' + service_version.version_number.to_s
      assert_content service_version.description
    end
    click_link ("Versión anterior")
    assert_content previous_version.name + ' R' + previous_version.version_number.to_s
    titles = find_all(".title")
    within titles[0] do
      assert_selector 'h1', text: previous_version.name + ' R' + previous_version.version_number.to_s
      assert_content previous_version.description
    end
  end

  test "Service Version show next versions" do
    service_version = service_versions(:servicio1_v1)
    next_version = service_version.next_version
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    within first(".title") do
      assert_selector 'h1', text: service_version.name + ' R' + service_version.version_number.to_s
    end
    click_link ("Versión siguiente")
    assert_content next_version.name + ' R' + next_version.version_number.to_s
    within first(".title") do
      assert_selector 'h1', text: next_version.name + ' R' + next_version.version_number.to_s
    end
  end

  test "Service Version show History" do
    service_version = service_versions(:servicio1_v3)
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    click_link ("Historial")
    within "#services" do
      assert_selector 'h1', text: service_version.name
      assert_selector 'h4', text: service_version.organization.name
      rows = page.all(:xpath, '//table/tbody/tr')
      assert rows.count == 3

      assert rows[0].text.include?("R3")
      assert rows[1].text.include?("R2")
      assert rows[2].text.include?("R1")
    end
  end

end
