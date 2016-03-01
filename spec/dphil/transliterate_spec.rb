# frozen_string_literal: true
require "spec_helper"

describe Dphil::Transliterate do
  iast_up = "ĀAĪIŪUṚ Ṝ Ḷ Ḹ ṬḌṄṆÑṂŚṢḤ || KAḤ KHAGAUGHĀṄCICCAUJĀ JHĀÑJÑO 'ṬAUṬHĪḌḌAṆḌHAṆAḤ | TATHODADHĪN PAPHARBĀBHĪRMAYO 'RILVĀŚIṢĀṂ SAHAḤ ||"
  iast = "āaīiūuṛ ṝ ḷ ḹ ṭḍṅṇñṃśṣḥ || kaḥ khagaughāṅciccaujā jhāñjño 'ṭauṭhīḍḍaṇḍhaṇaḥ | tathodadhīn papharbābhīrmayo 'rilvāśiṣāṃ sahaḥ ||"
  kh = "AaIiUuR RR lR lRR TDGNJMzSH || kaH khagaughAGciccaujA jhAJjJo 'TauThIDDaNDhaNaH | tathodadhIn papharbAbhIrmayo 'rilvAziSAM sahaH ||"
  slp1 = "AaIiUuf F x X wqNRYMSzH || kaH KagOGANciccOjA JAYjYo 'wOWIqqaRQaRaH | taTodaDIn paParbABIrmayo 'rilvASizAM sahaH ||"
  ascii = "aaiiuur r l l tdnnnmssh || kah khagaughanciccauja jhanjno 'tauthiddandhanah | tathodadhin papharbabhirmayo 'rilvasisam sahah ||"
  norm = "AaIiUuf F x X wqMMMMSz || ka KagOGAMciccOjA JAMjMo 'wOWIqqaMQaMa | taTodaDIM paParvABIrMayo 'rilvASizAM saha ||"

  control_word = "{{test}}"
  control_word_processed = "{{#4cee64562d96c832de8354ee3cdd4cbce66d10cd#}}"

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

  it "normalization properly processes control words" do
    expect(described_class.normalize_slp1(control_word)).to eq(control_word_processed)
  end

  it "normalization doesn't double-normalize control words" do
    expect(described_class.normalize_slp1(control_word_processed)).to eq(control_word_processed)
  end
end
