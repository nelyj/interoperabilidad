require "test_helper"

describe DataCategory do
  let(:data_category) { DataCategory.new }

  it "must be valid" do
    value(data_category).must_be :valid?
  end
end
