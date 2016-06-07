# frozen_string_literal: true
require "spec_helper"

describe Dphil::VerseAnalysis do
  test_verse = "dharma kṣetre kurukṣetre samavetā yuyutsavaḥ
                māmakāḥ pāṇḍavāś caiva kima kurvata saṃjaya"
  test_verse_syllables = %w[dhar mak ṣet re ku ruk ṣet re sa ma
                            ve tā yu yut sa vaḥ mā ma kāḥ pāṇ
                            ḍa vāś cai va ki ma kur va ta saṃ
                            ja ya]
  test_verse_syllables_weights = "GGGGLGGGLLGGLGLGGLGGLGGLLLGLLGLL"

  it "returns syllables of a string" do
    expect(described_class.syllables(test_verse)).to eq(test_verse_syllables)
  end

  it "returns weights of corresponding syllables" do
    expect(described_class.syllable_weight(test_verse_syllables))
      .to eq(test_verse_syllables_weights)
  end

  it "combines syllable and weight function into one method" do
    expect(described_class.verse_weight(test_verse)).to eq(test_verse_syllables_weights)
  end
end
