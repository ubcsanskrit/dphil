# frozen_string_literal: true
require "spec_helper"

describe Dphil::MetricalData do
  it { is_expected.to have_attributes(version: an_instance_of(String) & not_be_empty & be_frozen) }
  it { is_expected.to have_attributes(meters: a_kind_of(Hash) & not_be_empty & be_frozen) }
  it { is_expected.to have_attributes(patterns: a_kind_of(Hash) & not_be_empty & be_frozen) }
  it { is_expected.to have_attributes(regexes: a_kind_of(Hash) & not_be_empty & be_frozen) }
  it { is_expected.to have_attributes(all: a_kind_of(Hash) & not_be_empty & be_frozen) }

  %i[patterns regexes].each do |type|
    describe ".#{type}" do
      %i[full half pada].each do |size|
        it { expect(subject.send(type)).to respond_to(size) }
      end
    end
  end

  describe ".all" do
    %i[version meters patterns regexes].each do |type|
      it { expect(subject.send(:all)).to respond_to(type) }
    end
  end
end
