require 'fileutils'
require 'open3'
require 'pathname'
require 'tmpdir'
require 'support/helpers/emulation_helper'

RSpec.describe 'the translator' do
  include EmulationHelper

  TRANSLATOR_PATH = File.expand_path('../../../bin/translator', __FILE__)
  EXAMPLES_PATH = File.expand_path('../examples', __FILE__)

  EXT = { input: '.vm', script: '.tst' }

  Pathname.new(EXAMPLES_PATH).children.select(&:directory?).each do |directory_pathname|
    base_filename = directory_pathname.basename
    base_pathname = directory_pathname + base_filename
    script_pathname = base_pathname.sub_ext(EXT[:script])
    script_filename = script_pathname.basename

    script = File.read(script_pathname)
    output_filename = script.slice(/load (?<filename>[^,\s]+)/, :filename)
    actual_filename = script.slice(/output-file (?<filename>[^,\s]+)/, :filename)
    expected_filename = script.slice(/compare-to (?<filename>[^,\s]+)/, :filename)

    it "generates a #{output_filename} file which satisfies #{script_filename}" do
      input_pathname = base_pathname.sub_ext(EXT[:input])
      output, error, status = Open3.capture3(TRANSLATOR_PATH, input_pathname.to_path)
      expect(output).not_to be_empty
      expect(error).to be_empty
      expect(status).to be_success

      Dir.mktmpdir do |temporary_directory|
        FileUtils.cp_r directory_pathname, temporary_directory
        directory_pathname = Pathname.new(temporary_directory) + base_filename

        script_pathname = directory_pathname + script_filename
        output_pathname = directory_pathname + output_filename

        File.write(output_pathname, output)
        error, status = emulator.run(script_pathname.to_path)

        unless status.success?
          STDERR.write error

          expected_pathname = directory_pathname + expected_filename
          actual_pathname = directory_pathname + actual_filename
          expect(File.read(actual_pathname)).to eq File.read(expected_pathname)
        end
      end
    end
  end
end
