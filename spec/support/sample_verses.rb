# frozen_string_literal: true

RSpec.shared_context "sample_verses" do
  let(:sample_verses) { Psych.load_file(File.join(__dir__, "sample_verses.yml")) }
end
