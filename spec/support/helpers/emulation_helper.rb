require 'support/emulator'
require 'support/emulation'

module EmulationHelper
  EMULATOR_ENV_VAR = 'EMULATOR'

  def emulator
    Emulator.new(emulator_path)
  end

  def emulation_of(assembly)
    Emulation.new(emulator, assembly)
  end

  private

  def emulator_path
    ENV[EMULATOR_ENV_VAR] ||
      raise("can’t find CPU emulator script (please set the #{EMULATOR_ENV_VAR} environment variable)")
  end
end
