# frozen_string_literal: true
require "spec_helper"

describe Dphil::Transliterate do
  iast = "kaḥ khagaughāṅciccaujā jhāñjño 'ṭauṭhīḍḍaṇḍhaṇaḥ | tathodadhīn papharbābhīrmayo 'rilvāśiṣāṃ sahaḥ ||".unicode_normalize(:nfkc)
  kh = "kaH khagaughAGciccaujA jhAJjJo 'TauThIDDaNDhaNaH | tathodadhIn papharbAbhIrmayo 'rilvAziSAM sahaH ||".unicode_normalize(:nfkc)
  slp1 = "kaH KagOGANciccOjA JAYjYo 'wOWIqqaRQaRaH | taTodaDIn paParbABIrmayo 'rilvASizAM sahaH ||".unicode_normalize(:nfkc)

  ascii = "kah khagaughanciccauja jhanjno 'tauthiddandhanah | tathodadhin papharbabhirmayo 'rilvasisam sahah ||"
  norm = "kaH KagOGAMciccOjA JAMjMo 'wOWIqqaMQaMaH | taTodaDIM paParvABIrMayo 'rilvASizAM sahaH ||"

  it "transliterates IAST to ASCII" do
    expect(described_class.iast_ascii(iast)).to eq(ascii)
  end

  it "transliterates IAST to KH" do
    expect(described_class.iast_kh(iast)).to eq(kh)
  end

  it "transliterates KH to IAST" do
    expect(described_class.kh_iast(kh)).to eq(iast)
  end

  it "transliterates IAST to SLP1" do
    expect(described_class.iast_slp1(iast)).to eq(slp1)
  end

  it "transliterates SLP1 to IAST" do
    expect(described_class.slp1_iast(slp1)).to eq(iast)
  end

  it "normalizes SLP1" do
    expect(described_class.normalize_slp1(slp1)).to eq(norm)
  end

  it "normalizes IAST" do
    expect(described_class.normalize_iast(iast)).to eq(norm)
  end

  it "normalization properly processes control words"

  it "normalization doesn't double-normalize control words"
end
