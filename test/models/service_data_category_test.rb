require "test_helper"

describe ServiceDataCategory do
  let(:service_data_category) { ServiceDataCategory.new }

  it "must be valid" do
    value(service_data_category).must_be :valid?
  end
end
