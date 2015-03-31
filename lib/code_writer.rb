class CodeWriter
  def initialize(output)
    @output  = output
    @counter = 0
  end

  def set_file_name(filename)
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
    when 'neg', 'not'
      output.puts <<-EOF
        @SP
        A=M-1
        M=#{operand(command)}M
      EOF
    when 'eq', 'gt', 'lt'
      true_label, end_label = 2.times.map { generate_label }
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
        @#{true_label}
        D;J#{command.upcase}
        // Load M[SP]
        @SP
        A=M-1
        // M[SP-1] = 0
        M=0
        // Jump to (END)
        @#{end_label}
        0;JMP
        (#{true_label})
        // Load M[SP]
        @SP
        A=M-1
        // M[SP-1] = -1
        M=-1
        (#{end_label})
      EOF
    end
  end

  def write_push_pop(command, segment, index)
    case command
    when Parser::C_PUSH
      write_push(segment, index)
    when Parser::C_POP
      load_base_address_into_r13(segment, index)
      output.puts <<-EOF
        // SP--
        @SP         // A=0
        AM=M-1      // A,RAM[0]=RAM[0]-1=257
        // D = RAM[A] = the value to pop from the stack
        D=M         // D=RAM[257]=23
        // RAM[302] = 23
        @R13        // A=13
        A=M         // A=RAM[13]=302
        M=D         // RAM[302]=23
      EOF
    end
  end

  private

  attr_reader :output

  def write_push(segment, index)
    case segment
    when 'constant'
      output.puts <<-EOF
        // Load index into M[SP]
        @#{index}
        D=A
      EOF
    when 'local'
      load_base_address_into_r13(segment, index)
      output.puts <<-EOF
        @R13
        A=M
        D=M
      EOF
    end

    output.puts <<-EOF
      // RAM[SP]=D
      @SP
      A=M
      M=D
      // SP++
      @SP
      M=M+1
    EOF
  end

  def load_base_address_into_r13(segment, offset)
    if segment == 'temp'
      output.puts <<-EOF
        @#{5 + offset}
        D=A
      EOF
    else
      output.puts <<-EOF
        // Get base address of the local segment
        @#{base_address(segment)} // A=1
        D=M         // D=RAM[1]=300
      EOF

      if offset > 0
        output.puts <<-EOF
          // Add the index offset to the base address
          @#{offset}   // A=2
          D=A+D        // D=302
        EOF
      end
    end

    output.puts <<-EOF
      // Store the destination in R13
      @R13        // A=13
      M=D         // RAM[13]=302
    EOF
  end

  def operand(command)
    {
      'add' => '+',
      'sub' => '-',
      'and' => '&',
      'or'  => '|',
      'neg' => '-',
      'not' => '!'
    }.fetch(command)
  end

  def base_address(segment)
    {
      'local'    => 'LCL',
      'argument' => 'ARG',
      'this'     => 'THIS',
      'that'     => 'THAT'
    }.fetch(segment)
  end

  def generate_label
    @counter += 1
    "LABEL#{@counter}"
  end
end
