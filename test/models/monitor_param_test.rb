require "test_helper"

describe MonitorParam do
  let(:monitor_param) { MonitorParam.new }

  it "must be valid" do
    value(monitor_param).must_be :valid?
  end
end
