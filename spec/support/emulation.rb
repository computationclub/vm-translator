require 'tempfile'

class Emulation
  def initialize(emulator, assembly)
    self.emulator = emulator
    self.assembly = assembly
  end

  def run(ram, output_addresses, cycle_count)
    Tempfile.open('output') do |output_file|
      Tempfile.open(['assembly', '.asm']) do |assembly_file|
        assembly_file.write assembly
        assembly_file.flush

        Tempfile.open('script') do |script_file|
          script = generate_script(File.basename(assembly_file), File.basename(output_file), ram, output_addresses, cycle_count)
          script_file.write script
          script_file.flush

          error, status = emulator.run(script_file.path)
          raise error unless error.empty? && status.success?
        end
      end

      parse_output output_file.read
    end
  end

  private

  attr_accessor :emulator, :assembly

  def generate_script(assembly_path, output_path, ram, output_addresses, cycle_count)
    <<-eos
      load #{assembly_path},
      output-file #{output_path},
      output-list #{generate_output_list(output_addresses)};
      #{generate_assignments(ram)}
      repeat #{cycle_count} { ticktock; }
      output;
    eos
  end

  def generate_output_list(output_addresses)
    output_addresses.map { |address| "RAM[#{address}]%D2.6.2" }.join(' ')
  end

  def generate_assignments(ram)
    ram.map { |address, value| "set RAM[#{address}] #{value}," }.join(' ')
  end

  def parse_output(output)
    output.each_line.map(&method(:parse_output_line)).transpose.to_h
  end

  def parse_output_line(line)
    line.split(/\s+/).map { |field| field.slice(/-?\d+/) }.compact.map(&:to_i)
  end
end
