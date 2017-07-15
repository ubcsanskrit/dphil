# frozen_string_literal: true

require "spec_helper"
require "support/sample_verses"
require "support/sample_verses_defective"

describe Dphil::VerseAnalysis do
  include_context "sample_verses"
  include_context "sample_verses_defective"

  it "returns syllables of a string" do
    sample_verses.each do |v|
      expect(described_class.syllables(v["verse"])).to eq(v["syllables"])
    end
  end

  it "returns correct weights of corresponding syllables" do
    sample_verses.each do |v|
      expect(described_class.syllables_weights(v["syllables"])).to eq(v["weights"].gsub(/\s+/, ""))
    end
  end

  it "combines syllable and weight function into one method" do
    sample = sample_verses.first
    expect(described_class.verse_weights(sample["verse"])).to eq(sample["weights"].gsub(/\s+/, ""))
  end

  it ".identify returns empty Array for empty verse" do
    expect(described_class.identify_meter_manager("")).to be_a(Array).and be_empty
  end

  it ".identify returns non-empty Array for sample set" do
    sample_verses.each do |v|
      expect(described_class.identify_meter_manager(v["verse"])).to be_a(Array).and not_be_empty
    end
  end

  it ".identify returns non-empty Array for defective sample set" do
    sample_verses_defective.each do |v|
      expect(described_class.identify_meter_manager(v["verse"])).to be_a(Array).and not_be_empty
    end
  end

  it ".identify returns useful information for a defective sample" do
    pending "WIP"

    raise
  end
end
