require 'test_helper'
class ServiceVersionMonitorWorkerTest < Minitest::Test
  def test_monitor_existing_and_current_service_version
    service_version_mock = Minitest::Mock.new
    service_version_mock.expect :perform_health_check!, nil
    service_version_mock.expect :current?, true
    ServiceVersion.stub :find, -> (id) {
      assert_equal 42,  id
      service_version_mock
    } do
      ServiceVersionMonitorWorker.new.perform(42)
    end
    assert_mock service_version_mock
  end

  def test_monitor_non_existing_service_version
    ServiceVersionMonitorWorker.new.perform(-1)
    assert true # Nothing raised
  end

  def test_monitor_non_current_service_version
    service_version_mock = Minitest::Mock.new
    service_version_mock.expect :current?, false
    ServiceVersion.stub :find, -> (id) {
      assert_equal 42,  id
      service_version_mock
    } do
      ServiceVersionMonitorWorker.new.perform(42)
    end
    assert_mock service_version_mock
  end
end
