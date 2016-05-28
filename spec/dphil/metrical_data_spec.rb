# frozen_string_literal: true
require "spec_helper"

describe Dphil::MetricalData do
  it { is_expected.to have_attributes(version: an_instance_of(String) & not_be_empty) }
  it { is_expected.to have_attributes(meters: an_instance_of(Hamster::Hash) & not_be_empty) }
  it { is_expected.to have_attributes(patterns: an_instance_of(Hamster::Hash) & not_be_empty) }
  it { is_expected.to have_attributes(regexes: an_instance_of(Hamster::Hash) & not_be_empty) }
  it { is_expected.to have_attributes(all: an_instance_of(Hamster::Hash) & not_be_empty) }
end
