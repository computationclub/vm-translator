class CodeWriter
  def initialize(output)
    @output = output
  end

  def set_file_name(filename)
  end

  def operand(command)
    {
      'add' => '+',
      'sub' => '-',
      'and' => '&',
      'or'  => '|',
    }.fetch(command)
  end

  def write_arithmetic(command)
    case command
    when 'add', 'sub', 'and', 'or'
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
        M=M#{operand(command)}D
      EOF
    when 'eq', 'gt', 'lt'
      output.puts <<-EOF
        @SP
        // SP--
        MD=M-1
        // Load M[SP]
        A=M
        D=M
        // Load M[SP-1]
        A=A-1
        // Subtract M[SP-1] from M[SP]
        D=M-D
        // If the result satisfies command then jump to (TRUE)
        @TRUE
        D;J#{command.upcase}
        // Load M[SP]
        @SP
        A=M-1
        // M[SP-1] = 0
        M=0
        // Jump to (END)
        @END
        0;JMP
        (TRUE)
        // Load M[SP]
        @SP
        A=M-1
        // M[SP-1] = -1
        M=-1
        (END)
      EOF
    end
  end

  def write_push_pop(command, segment, index)
    output.puts <<-EOF
      // Load index into M[SP]
      @#{index}
      D=A
      @SP
      A=M
      M=D
      // SP++
      @SP
      M=M+1
    EOF
  end

  private

  attr_reader :output
end
