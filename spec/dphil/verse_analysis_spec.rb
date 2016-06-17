# frozen_string_literal: true
require "spec_helper"
require "support/sample_verses"

describe Dphil::VerseAnalysis do
  include_context "sample_verses"

  it "returns syllables of a string" do
    sample_verses.each do |v|
      expect(described_class.syllables(v["verse"])).to eq(v["syllables"])
    end
  end

  it "returns correct weights of corresponding syllables" do
    sample_verses.each do |v|
      expect(described_class.syllable_weight(v["syllables"])).to eq(v["weights"].gsub(/\s+/, ""))
    end
  end

  it "combines syllable and weight function into one method" do
    sample = sample_verses.first
    expect(described_class.verse_weight(sample["verse"])).to eq(sample["weights"].gsub(/\s+/, ""))
  end
end
