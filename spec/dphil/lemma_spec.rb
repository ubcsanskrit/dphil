# frozen_string_literal: true
require "spec_helper"

describe Dphil::Lemma do
  lemma_source = %(<pb n="1v" facs="1"/><lb n="1"/><div type="verse" id="Ś0-1"> praṇamya </div>)

  it "instantiates" do
    expect(described_class.new(lemma_source, 1)).to be_a(described_class)
  end
end
