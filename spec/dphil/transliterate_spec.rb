# frozen_string_literal: true
require "spec_helper"

describe Dphil::Transliterate do
  iast_up = "Ā A Ī I Ū U Ṛ Ṝ Ḷ Ḹ Ṭ Ḍ Ṅ Ṇ Ñ Ṃ Ś Ṣ Ḥ || " \
            "KAḤ KHAGAUGHĀṄCICCAUJĀ JHĀÑJÑO 'ṬAUṬHĪḌḌAṆḌHAṆAḤ | " \
            "TATHODADHĪN PAPHARBĀBHĪRMAYO 'RILVĀŚIṢĀṂ SAHAḤ || {#Ś01-1.1#} {#Ś01-1.2BḤ#} .-_"
  iast = "ā a ī i ū u ṛ ṝ ḷ ḹ ṭ ḍ ṅ ṇ ñ ṃ ś ṣ ḥ || " \
         "kaḥ khagaughāṅciccaujā jhāñjño 'ṭauṭhīḍḍaṇḍhaṇaḥ | " \
         "tathodadhīn papharbābhīrmayo 'rilvāśiṣāṃ sahaḥ || {#Ś01-1.1#} {#Ś01-1.2BḤ#} .-_"
  kh = "A a I i U u R RR lR lRR T D G N J M z S H || " \
       "kaH khagaughAGciccaujA jhAJjJo 'TauThIDDaNDhaNaH | " \
       "tathodadhIn papharbAbhIrmayo 'rilvAziSAM sahaH || {#Ś01-1.1#} {#Ś01-1.2BḤ#} .-_"
  slp1 = "A a I i U u f F x X w q N R Y M S z H || " \
         "kaH KagOGANciccOjA JAYjYo 'wOWIqqaRQaRaH | " \
         "taTodaDIn paParbABIrmayo 'rilvASizAM sahaH || {#Ś01-1.1#} {#Ś01-1.2BḤ#} .-_"
  ascii = "a a i i u u r r l l t d n n n m s s h || " \
          "kah khagaughanciccauja jhanjno 'tauthiddandhanah | " \
          "tathodadhin papharbabhirmayo 'rilvasisam sahah || {#Ś01-1.1#} {#Ś01-1.2BḤ#} .-_"
  unknown = "éâ"

  norm = "A a I i U u f F x X w q N R Y M S z H || " \
         "ka KagOGAMciccOjA JAMjMo wOWIqqaMQaMa | " \
         "taTodaDIM paParvABIrMayo rilvASizAM saha || " \
         "{##a232b8c9daf123038c5c13aee182144f774dc452##} " \
         "{##c186324615c533a5167d622fbaa51e9725676eab##} "

  control_word = "{#test#}"
  control_word_processed = "{##a94a8fe5ccb19ba61c4c0873d391e987982fbbd3##}"

  it "downcases unicode properly (non-destructive)" do
    iast_up_copy = iast_up.dup
    expect(described_class.unicode_downcase(iast_up_copy)).to eq(iast)
    expect(iast_up_copy).to eq(iast_up)
  end

  it "downcases unicode properly (destructive)" do
    iast_up_copy = iast_up.dup
    described_class.unicode_downcase!(iast_up_copy)
    expect(iast_up_copy).to eq(iast)
  end

  describe ".detect" do
    it "detects IAST" do
      expect(described_class.detect(iast_up)).to eq(:iast)
      expect(described_class.detect(iast)).to eq(:iast)
    end

    it "detects SLP1" do
      expect(described_class.detect(slp1)).to eq(:slp1)
    end

    it "detects KH" do
      expect(described_class.detect(kh)).to eq(:hk)
    end

    it "returns nil if it can't tell" do
      expect(described_class.detect(unknown)).to be_nil
    end
  end

  it "transliterates IAST to ASCII" do
    expect(described_class.to_ascii(iast)).to eq(ascii)
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
