require 'test_helper'
require 'sidekiq/testing'

class MonitorParamTest < ActiveSupport::TestCase

  setup do
    Sidekiq::Testing.fake!
    # If no service versions are current, nothing happens thus nothing can be tested
    Organization.first.services.last.service_versions.last.make_current_version
    # Make sure there is no "noise"
    ServiceVersionMonitorWorker.jobs.clear
    Sidekiq::Worker.clear_all
    Sidekiq::Cron::Job.destroy_all!
  end

  def teardown
    Sidekiq::Testing.disable!
  end

  test "Reschedules health checks for services" do
    # Make sure both queues involved are empty
    assert_equal 0, Sidekiq::Cron::Job.count
    assert_equal 0, ServiceVersionMonitorWorker.jobs.size
    # Reschedule the health check...
    Organization.first.monitor_param.reschedule_monitoring_for_all_organization_services
    # Make sure the cron is created...
    assert_equal 1, Sidekiq::Cron::Job.count
    expected_job_name = Organization.first.services.last.service_versions.last.scheduled_health_check_job_name
    # ...with the name we expect it to have
    assert_equal expected_job_name, Sidekiq::Cron::Job.all.first.name
    # Run the cronjob
    Sidekiq::Cron::Job.all.first.enque!
    # The service version monitor worker job was created
    assert_equal 1, ServiceVersionMonitorWorker.jobs.size
  end
end
