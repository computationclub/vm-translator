require 'fileutils'
require 'open3'
require 'pathname'
require 'tmpdir'
require 'support/helpers/emulation_helper'

RSpec.describe 'the translator' do
  include EmulationHelper

  TRANSLATOR_PATH = File.expand_path('../../../bin/translator', __FILE__)
  EXAMPLES_PATH = File.expand_path('../examples', __FILE__)

  EXT = { input: '.vm', output: '.asm', script: '.tst', expected: '.cmp', actual: '.out' }

  Pathname.new(EXAMPLES_PATH).children.select(&:directory?).each do |directory_pathname|
    base_filename = directory_pathname.basename
    base_pathname = directory_pathname + base_filename
    output_pathname = base_pathname.sub_ext(EXT[:output])
    script_pathname = base_pathname.sub_ext(EXT[:script])

    it "generates a #{output_pathname.basename} file which satisfies #{script_pathname.basename}" do
      input_pathname = base_pathname.sub_ext(EXT[:input])
      output, error, status = Open3.capture3(TRANSLATOR_PATH, input_pathname.to_path)
      expect(output).not_to be_empty
      expect(error).to be_empty
      expect(status).to be_success

      Dir.mktmpdir do |dir|
        expected_pathname = base_pathname.sub_ext(EXT[:expected])
        dir_pathname = Pathname.new(dir)

        FileUtils.cp [script_pathname, expected_pathname], dir_pathname

        script_pathname = dir_pathname + script_pathname.basename
        output_pathname = dir_pathname + output_pathname.basename

        File.write(output_pathname, output)
        error, status = emulator.run(script_pathname.to_path)

        unless status.success?
          STDERR.write error

          expected_pathname = script_pathname.sub_ext(EXT[:expected])
          actual_pathname = script_pathname.sub_ext(EXT[:actual])
          expect(File.read(actual_pathname)).to eq File.read(expected_pathname)
        end
      end
    end
  end
end
