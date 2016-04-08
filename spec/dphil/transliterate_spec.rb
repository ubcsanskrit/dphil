# frozen_string_literal: true
require "spec_helper"

describe Dphil::Transliterate do
  iast_up = "ĀAĪIŪUṚ Ṝ Ḷ Ḹ ṬḌṄṆÑṂŚṢḤ || KAḤ KHAGAUGHĀṄCICCAUJĀ JHĀÑJÑO 'ṬAUṬHĪḌḌAṆḌHAṆAḤ | TATHODADHĪN PAPHARBĀBHĪRMAYO 'RILVĀŚIṢĀṂ SAHAḤ || {{Ś01-1.1}} {{Ś01-1.2BḤ}}"
  iast = "āaīiūuṛ ṝ ḷ ḹ ṭḍṅṇñṃśṣḥ || kaḥ khagaughāṅciccaujā jhāñjño 'ṭauṭhīḍḍaṇḍhaṇaḥ | tathodadhīn papharbābhīrmayo 'rilvāśiṣāṃ sahaḥ || {{Ś01-1.1}} {{Ś01-1.2BḤ}}"
  kh = "AaIiUuR RR lR lRR TDGNJMzSH || kaH khagaughAGciccaujA jhAJjJo 'TauThIDDaNDhaNaH | tathodadhIn papharbAbhIrmayo 'rilvAziSAM sahaH || {{Ś01-1.1}} {{Ś01-1.2BḤ}}"
  slp1 = "AaIiUuf F x X wqNRYMSzH || kaH KagOGANciccOjA JAYjYo 'wOWIqqaRQaRaH | taTodaDIn paParbABIrmayo 'rilvASizAM sahaH || {{Ś01-1.1}} {{Ś01-1.2BḤ}}"
  ascii = "aaiiuur r l l tdnnnmssh || kah khagaughanciccauja jhanjno 'tauthiddandhanah | tathodadhin papharbabhirmayo 'rilvasisam sahah || {{Ś01-1.1}} {{Ś01-1.2BḤ}}"

  norm = "AaIiUuf F x X wqMMMMSz || ka KagOGAMciccOjA JAMjMo 'wOWIqqaMQaMa | taTodaDIM paParvABIrMayo 'rilvASizAM saha || {{#a232b8c9daf123038c5c13aee182144f774dc452#}} {{#c186324615c533a5167d622fbaa51e9725676eab#}}"

  control_word = "{{test}}"
  control_word_processed = "{{#a94a8fe5ccb19ba61c4c0873d391e987982fbbd3#}}"

  it "downcases unicode properly" do
    expect(described_class.unicode_downcase(iast_up)).to eq(iast)
  end

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

  it "double-normalization doesn't change" do
    expect(described_class.normalize_slp1(norm)).to eq(norm)
  end

  it "normalization properly processes control words" do
    expect(described_class.normalize_slp1(control_word)).to eq(control_word_processed)
  end

  it "normalization doesn't double-normalize control words" do
    expect(described_class.normalize_slp1(control_word_processed)).to eq(control_word_processed)
  end
end
