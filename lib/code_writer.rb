require_relative 'assembly_writer'

class CodeWriter
  def initialize(output)
    @output  = AssemblyWriter.new(output)
    @counter = 0
    @implementations_cache = {}
  end

  def set_file_name(filename)
    @filename = filename
  end

  def close
    output.close
  end

  def write_init
    output.store(value: 256, into: 'SP')
    write_call("Sys.init", 0)
  end

  def write_arithmetic(command)
    cache_implementation(command) do
      case command
      when 'add', 'sub', 'and', 'or'
        output.puts <<-EOF
          @SP
          // SP--
          AMD=M-1
          // Load M[SP]
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
          AMD=M-1
          // Load M[SP]
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
        EOF
        output.jump_to(end_label)

        output.define_label(true_label)
        output.puts <<-EOF
          // Load M[SP]
          @SP
          A=M-1
          // M[SP-1] = -1
          M=-1
        EOF
        output.define_label(end_label)
      end
    end
  end

  def write_push_pop(command, segment, index)
    case command
    when Parser::C_PUSH
      cache_implementation("push_#{filename}_#{segment}_#{index}") do
        write_push(segment, index)
      end
    when Parser::C_POP
      cache_implementation("pop_#{filename}_#{segment}_#{index}") do
        load_base_address_into_r13(segment, index)
        output.pop_register_d
        output.puts <<-EOF
          @R13
          A=M
          M=D
        EOF
      end
    end
  end

  def write_label(label)
    output.define_label("#{function_name}$#{label}")
  end

  def write_goto(label)
    output.jump_to("#{function_name}$#{label}")
  end

  def write_if(label)
    output.pop_register_d
    output.puts <<-EOF
      // Jump to the label's address if D is nonzero
      @#{function_name}$#{label}
      D;JNE
    EOF
  end

  def write_function(function_name, num_locals)
    @function_name = function_name
    output.puts "(#{function_name})"

    cache_implementation("push_locals_#{num_locals}") do
      num_locals.times do
        write_push 'constant', 0
      end
    end
  end

  def write_call(function_name, num_args)
    return_label = generate_label
    output.push_value(return_label)

    cache_implementation("call_#{num_args}") do
      %w(LCL ARG THIS THAT).each do |label|
        output.push_value_at(label)
      end

      output.puts <<-EOF
        // ARG = SP - num_args - 5
        @SP
        D=M
        @#{num_args + 5}
        D=D-A
        @ARG
        M=D
      EOF

      output.copy(from: 'SP', to: 'LCL')
    end

    output.jump_to(function_name)
    output.define_label(return_label)
  end

  def write_return
    cache_implementation("return") do
      output.puts <<-EOF
        // FRAME = LCL
        @LCL
        D=M     // D=RAM[LCL]
        @FRAME
        M=D     // RAM[FRAME]=D=RAM[LCL]

        // RET = *(FRAME - 5)
        @5
        A=D-A   // A=RAM[FRAME]-5
        D=M     // D=RAM[RAM[FRAME]-5]
        @RET
        M=D     // RAM[RET]=RAM[RAM[FRAME]-5]
      EOF

      # *ARG = pop()
      output.pop_register_d
      output.puts <<-EOF
        @ARG
        A=M     // A=RAM[ARG]
        M=D     // RAM[RAM[ARG]] = pop()

        // SP = ARG+1
        @ARG
        D=M+1
        @SP
        M=D

        // THAT = *(FRAME - 1)
        @FRAME
        A=M-1   // A=RAM[FRAME-1]
        D=M     // D=RAM[RAM[FRAME-1]]
        @THAT
        M=D     // RAM[THAT]=RAM[RAM[FRAME-1]]

        // THIS = *(FRAME - 2)
        @FRAME
        A=M-1
        A=A-1
        D=M
        @THIS
        M=D

        // ARG = *(FRAME - 3)
        @FRAME
        A=M-1
        A=A-1
        A=A-1
        D=M
        @ARG
        M=D

        // LCL = *(FRAME - 4)
        @FRAME
        A=M-1
        A=A-1
        A=A-1
        A=A-1
        D=M
        @LCL
        M=D

        // goto RET
        @RET
        A=M
        0;JMP
      EOF
    end
  end

  private

  attr_reader :output, :filename, :function_name, :implementations_cache

  def write_push(segment, index)
    case segment
    when 'constant'
      output.push_value(index)
    else
      load_base_address_into_r13(segment, index)
      output.puts <<-EOF
        @R13
        A=M
        D=M
      EOF

      output.push_register_d
    end
  end

  def load_base_address_into_r13(segment, offset)
    load_destination_into_d(segment, offset)

    output.puts <<-EOF
      // Store the destination in R13
      @R13        // A=13
      M=D         // RAM[13]=302
    EOF
  end

  def load_destination_into_d(segment, offset)
    output.puts "@#{symbol_for_segment(segment, offset)}"

    if symbol_known_at_compile_time?(segment)
      output.puts "D=A"
    else
      output.puts "D=M"
      apply_offset_at_runtime(offset)
    end
  end

  def symbol_for_segment(segment, offset)
    case segment
    when 'temp'
      5 + offset
    when 'pointer'
      3 + offset
    when 'static'
      "#{filename}.#{offset}"
    else
      base_address(segment)
    end
  end

  def symbol_known_at_compile_time?(segment)
    %w(temp pointer static).include? segment
  end

  def apply_offset_at_runtime(offset)
    return if offset.zero?

    output.puts <<-EOF
      // Add the index offset to the base address
      @#{offset}
      D=A+D
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

  def generate_label(text = "LABEL")
    @counter += 1
    "#{text}.#{@counter}"
  end

  # Only output code for an implementation subroutine once, otherwise we
  # are inlining everything and the code bloats enough to not fit the ROM
  def cache_implementation(name)
    return_label = generate_label("RETURN_#{name.upcase}")
    function_label = "__INTERNAL__#{name.upcase}"

    output.puts <<-EOF
      @#{return_label}
      D=A
    EOF

    output.jump_to(function_label)

    implementations_cache[name] ||= begin
      output.define_label(function_label)
      # Using R14 rather than some static memory as it interferes with the test assumptions >_<
      output.puts <<-EOF
        // Save return address
        @R14
        M=D
      EOF

      yield

      output.puts <<-EOF
        @R14
        A=M;JMP
      EOF

      true # Only once! \o/
    end

    output.define_label(return_label)
  end
end
