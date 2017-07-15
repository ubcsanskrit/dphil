# frozen_string_literal: true

RSpec.shared_context "sample_verses_defective" do
  let(:sample_verses_defective) { Psych.load_file(File.join(__dir__, "sample_verses_defective.yml")) }
end
