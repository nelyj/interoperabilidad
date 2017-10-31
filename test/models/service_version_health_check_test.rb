require "test_helper"

describe ServiceVersionHealthCheck do
  let(:service_version_health_check) { ServiceVersionHealthCheck.new }

  it "must be valid" do
    value(service_version_health_check).must_be :valid?
  end
end
