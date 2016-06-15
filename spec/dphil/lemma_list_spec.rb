# frozen_string_literal: true
require "spec_helper"

describe Dphil::LemmaList do
  let(:sample_tei_xml) { Dphil::TeiXML.new(File.read(File.join(__dir__, "..", "fixtures", "tei-document.xml"))) }

  it "instantiates from sample xml data" do
    expect(described_class.new(sample_tei_xml)).to be_a(Dphil::LemmaList)
  end

  it "instantiates from empty data" do
    expect(described_class.new("")).to be_a(Dphil::LemmaList)
  end

  describe "#members" do
    it { expect(described_class.new("")).to respond_to(:members) }
    it { expect(described_class.new("").members).to be_a(Array) }
    it "is not empty with sample data" do
      expect(described_class.new(sample_tei_xml).members).to not_be_empty
    end
    it "is empty with empty data" do
      expect(described_class.new("").members).to be_empty
    end
  end

  describe "#size" do
    it { expect(described_class.new("")).to respond_to(:size) }
    it { expect(described_class.new("").size).to be_a(Integer) }
    it "is not 0 with sample data" do
      expect(described_class.new(sample_tei_xml).size).to not_be_zero
    end
    it "is 0 with empty data" do
      expect(described_class.new("").size).to be_zero
    end
  end
end
