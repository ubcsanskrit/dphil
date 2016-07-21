# frozen_string_literal: true
require "spec_helper"
require "support/sample_verses"

describe Dphil::Verse do
  include_context "sample_verses"

  it "instantiates" do
    pending "WIP"
    expect(described_class.new(sample_verses.first["verse"])).to be_a(described_class)
    raise
  end
end
