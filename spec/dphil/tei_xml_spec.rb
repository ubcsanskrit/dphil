# frozen_string_literal: true

require "spec_helper"

describe Dphil::TeiXML do
  let(:sample) { described_class.new(File.read(File.join(__dir__, "..", "fixtures", "tei-document.xml"))) }
  let(:empty_sample) { described_class.new("") }

  it "Instantiates from XML data" do
    expect(sample).to be_an_instance_of(described_class)
  end

  it "Instantiates from empty data" do
    expect(empty_sample).to be_an_instance_of(described_class)
  end

  describe "#empty?" do
    it { expect(sample).to respond_to(:empty?) }

    it "sample instance should not be empty" do
      expect(sample.empty?).to be_falsey
    end

    it "empty sample instance should be empty" do
      expect(empty_sample.empty?).to be_truthy
    end
  end
end
