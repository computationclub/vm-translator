require 'fileutils'
require 'pathname'

class ExampleFromDirectory
  SCRIPT_EXT, INPUT_EXT = '.tst', '.vm'
  PENDING_FILENAME = '.pending'

  def initialize(pathname)
    self.pathname = pathname
  end

  def input_pathname
    base_pathname.sub_ext(INPUT_EXT)
  end

  def output_pathname
    pathname + output_filename
  end

  def script_pathname
    base_pathname.sub_ext(SCRIPT_EXT)
  end

  def actual_pathname
    pathname + actual_filename
  end

  def expected_pathname
    pathname + expected_filename
  end

  def pending?
    File.exist?(pathname + PENDING_FILENAME)
  end

  def copy_into(destination)
    FileUtils.cp_r pathname, destination
    self.class.new(Pathname.new(destination) + base_filename)
  end

  def self.all_in(parent)
    Pathname.new(parent).children.select(&:directory?).map(&method(:new))
  end

  private

  attr_accessor :pathname

  def base_filename
    pathname.basename
  end

  def base_pathname
    pathname + base_filename
  end

  def script
    @script ||= File.read(script_pathname)
  end

  def output_filename
    argument_to_script_command 'load'
  end

  def actual_filename
    argument_to_script_command 'output-file'
  end

  def expected_filename
    argument_to_script_command 'compare-to'
  end

  def argument_to_script_command(command)
    script.slice(/#{Regexp.escape(command)} (?<filename>[^,\s]+)/, :filename)
  end
end
