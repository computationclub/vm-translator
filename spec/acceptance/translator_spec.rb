require 'open3'
require 'tmpdir'
require 'support/example_from_directory'
require 'support/helpers/emulation_helper'

RSpec.describe 'the translator' do
  include EmulationHelper

  TRANSLATOR_PATH = File.expand_path('../../../bin/translator', __FILE__)
  EXAMPLES_PATH = File.expand_path('../examples', __FILE__)

  ExampleFromDirectory.all_in(EXAMPLES_PATH).each do |example|
    it "generates a #{example.output_pathname.basename} file which satisfies #{example.script_pathname.basename}" do
      output, error, status = Open3.capture3(TRANSLATOR_PATH, example.input_pathname.to_path)
      expect(error).to be_empty
      expect(status).to be_success
      expect(output).not_to be_empty

      Dir.mktmpdir do |temporary_directory|
        example = example.copy_into(temporary_directory)

        File.write(example.output_pathname, output)
        error, status = emulator.run(example.script_pathname.to_path)

        unless status.success?
          STDERR.write error
          expect(File.read(example.actual_pathname)).to eq File.read(example.expected_pathname)
        end
      end
    end
  end
end
