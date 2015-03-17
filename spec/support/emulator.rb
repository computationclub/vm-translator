require 'open3'

class Emulator
  def initialize(emulator_path)
    self.emulator_path = emulator_path
  end

  def run(script_path)
    _, error, status = Open3.capture3(*interpreter, emulator_path, script_path)
    [error, status]
  end

  private

  attr_accessor :emulator_path

  def interpreter
    shebang_line.slice(/(?<=\A#!).*/).split
  end

  def shebang_line
    File.foreach(emulator_path).first
  end
end
