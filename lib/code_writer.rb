class CodeWriter
  def initialize(output)
    @output = output
  end

  def set_file_name(filename)
  end

  def write_arithmetic(command)
    output.puts <<-EOF
      @SP
      // SP--
      MD=M-1
      // Load M[SP]
      A=M
      D=M
      // Load M[SP-1]
      A=A-1
      // Add M[SP] to M[SP-1]
      // Store results in M[SP-1]
      M=D+M
    EOF
  end

  private

  attr_reader :output
end
