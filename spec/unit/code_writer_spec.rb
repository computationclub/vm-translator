require 'code_writer'
require 'parser'
require 'stringio'
require 'support/control_flow_detector'
require 'support/function_lifetime'
require 'support/stack_frame'
require 'support/helpers/assembly_helper'
require 'support/helpers/emulation_helper'
require 'support/matchers/ram_matchers'

RSpec.describe CodeWriter do
  let(:output) { StringIO.new }
  let(:code_writer) { CodeWriter.new(output) }

  def assembly
    output.string
  end

  describe '#set_file_name' do
    it 'accepts a new file name' do
      expect { code_writer.set_file_name('SomeFile.vm') }.not_to raise_error
    end
  end

  describe '#write_arithmetic' do
    include EmulationHelper
    include RamMatchers

    before(:example) do
      code_writer.write_arithmetic command
    end

    [
      { command: :add,  operation: :+,   cases: [[1, 2]]                   },
      { command: :sub,  operation: :-,   cases: [[2, 5]]                   },
      { command: :neg,  operation: :-@,  cases: [6]                        },
      { command: :eq,   operation: :==,  cases: [[2, 3], [3, 3], [4, 3]]   },
      { command: :gt,   operation: :>,   cases: [[2, 3], [3, 3], [4, 3]]   },
      { command: :lt,   operation: :<,   cases: [[2, 3], [3, 3], [4, 3]]   },
      { command: :and,  operation: :&,   cases: [[0b01111100, 0b00111110]] },
      { command: :or,   operation: :|,   cases: [[0b01111100, 0b00111110]] },
      { command: :not,  operation: :~,   cases: [0b01111100]               }
    ].each do |options|
      command = options[:command].to_s

      context "when the command is “#{command}”" do
        let(:command) { command }

        options[:cases].each do |args|
          args = Array(args)
          result = options[:operation].to_proc.call(*args)

          it "writes assembly that computes #{args.join(', ')} => #{result}" do
            expect(emulation_of(assembly)).to change_ram.from(stack: args).to(stack: result)
          end
        end
      end
    end
  end

  describe '#write_push_pop' do
    include EmulationHelper
    include RamMatchers

    before(:example) do
      code_writer.write_push_pop command_type, segment, index
    end

    context 'when the command is a push' do
      let(:command_type) { Parser::C_PUSH }

      [
        { segment: :constant,  index: 57,  before: { stack: [2, 3]                             },  after: { stack: [2, 3, 57] } },
        { segment: :local,     index: 2,   before: { stack: [2, 3], local:    [17, 19, 23, 29] },  after: { stack: [2, 3, 23] } },
        { segment: :argument,  index: 2,   before: { stack: [2, 3], argument: [17, 19, 23, 29] },  after: { stack: [2, 3, 23] } },
        { segment: :this,      index: 2,   before: { stack: [2, 3], this:     [17, 19, 23, 29] },  after: { stack: [2, 3, 23] } },
        { segment: :that,      index: 2,   before: { stack: [2, 3], that:     [17, 19, 23, 29] },  after: { stack: [2, 3, 23] } },
        { segment: :temp,      index: 2,   before: { stack: [2, 3], temp:     [17, 19, 23, 29] },  after: { stack: [2, 3, 23] } },
        { segment: :pointer,   index: 1,   before: { stack: [2, 3], pointer:  [17, 19]         },  after: { stack: [2, 3, 19] } },
        { segment: :static,    index: 2,   before: { stack: [2, 3], static:   [17, 19, 23, 29] },  after: { stack: [2, 3, 17] } }
      ].each do |options|
        segment = options[:segment].to_s

        context "when the segment is “#{segment}”" do
          let(:segment)    { segment }
          let(:index)      { options[:index]  }
          let(:ram_before) { options[:before] }
          let(:ram_after)  { options[:after]  }

          it "writes assembly to push a value onto the stack from the “#{segment}” segment" do
            expect(emulation_of(assembly)).to change_ram.from(ram_before).to(ram_after)
          end
        end
      end
    end

    context 'when the command is a pop' do
      let(:command_type) { Parser::C_POP }

      [
        { segment: :local,     index: 2,  before: { stack: [2, 3], local:    [17, 19, 23, 29] },  after: { stack: 2, local:    [17, 19, 3, 29] } },
        { segment: :argument,  index: 2,  before: { stack: [2, 3], argument: [17, 19, 23, 29] },  after: { stack: 2, argument: [17, 19, 3, 29] } },
        { segment: :this,      index: 2,  before: { stack: [2, 3], this:     [17, 19, 23, 29] },  after: { stack: 2, this:     [17, 19, 3, 29] } },
        { segment: :that,      index: 2,  before: { stack: [2, 3], that:     [17, 19, 23, 29] },  after: { stack: 2, that:     [17, 19, 3, 29] } },
        { segment: :temp,      index: 2,  before: { stack: [2, 3], temp:     [17, 19, 23, 29] },  after: { stack: 2, temp:     [17, 19, 3, 29] } },
        { segment: :pointer,   index: 1,  before: { stack: [2, 3], pointer:  [17, 19]         },  after: { stack: 2, pointer:  [17, 3]         } },
        { segment: :static,    index: 2,  before: { stack: [2, 3], static:   [17, 19, 23, 29] },  after: { stack: 2, static:   [3, 19, 23, 29] } }
      ].each do |options|
        segment = options[:segment].to_s

        context "when the segment is “#{segment}”" do
          let(:segment)    { segment }
          let(:index)      { options[:index]  }
          let(:ram_before) { options[:before] }
          let(:ram_after)  { options[:after]  }

          it "writes assembly to pop a value from the stack into the “#{segment}” segment" do
            expect(emulation_of(assembly)).to change_ram.from(ram_before).to(ram_after)
          end
        end
      end
    end
  end

  describe '#write_init' do
    include EmulationHelper
    include RamMatchers

    let(:frame) { StackFrame.new(pointers: { stack: 256 }) }
    let(:lifetime) { FunctionLifetime.new(frame: frame) }
    let(:frame_after) { lifetime.frame_after_call_command }
    let(:pointers_after) { frame_after.pointers }

    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_jump('Sys.init') do
        code_writer.write_init
      end
    end

    it 'writes assembly to initialise the stack pointer', :pending do
      expect(emulation_of(assembly)).to change_ram.
        from({}).to(pointers: { stack: pointers_after[:stack] })
    end

    it 'writes assembly to transfer control to system init function', :pending do
      expect(emulation_of(assembly)).to change_ram.from({}).to(detector.success)
    end
  end

  describe '#write_label' do
    include EmulationHelper
    include RamMatchers

    let(:label) { 'myLabel' }
    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_local_label(label) do
        code_writer.write_label label
      end
    end

    it 'writes assembly to insert a label' do
      expect(emulation_of(assembly)).to change_ram.from({}).to(detector.success)
    end
  end

  describe '#write_goto' do
    include EmulationHelper
    include RamMatchers

    let(:label) { 'myLabel' }
    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_goto(label) do
        code_writer.write_goto label
      end
    end

    it 'writes assembly to perform a jump' do
      expect(emulation_of(assembly)).to change_ram.from({}).to(detector.success)
    end
  end

  describe '#write_if' do
    include EmulationHelper
    include RamMatchers

    let(:label) { 'myLabel' }
    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_goto(label) do
        code_writer.write_if label
      end
    end

    context 'when the stack’s top element is non-zero' do
      it 'writes assembly to pop a value from the stack' do
        expect(emulation_of(assembly)).to change_ram.from(stack: [2, 5]).to(stack: [2])
      end

      it 'writes assembly to perform a jump' do
        expect(emulation_of(assembly)).to change_ram.from(stack: [2, 5]).to(detector.success)
      end
    end

    context 'when the stack’s top element is zero' do
      it 'writes assembly to pop a value from the stack' do
        expect(emulation_of(assembly)).to change_ram.from(stack: [2, 0]).to(stack: [2])
      end

      it 'writes assembly to not perform a jump' do
        expect(emulation_of(assembly)).not_to change_ram.from(stack: [2, 0]).to(detector.success)
      end
    end
  end

  describe '#write_call' do
    include EmulationHelper
    include RamMatchers

    let(:function_name) { 'myFunction' }
    let(:arguments) { [1234, 47] }

    let(:frame) {
      StackFrame.new(
        lengths:  { local: 5 },
        pointers: { stack: 310, this: 3010, that: 4010 }
      )
    }
    let(:lifetime) {
      FunctionLifetime.new(
        frame: frame,
        lengths: { argument: arguments.length }
      )
    }
    let(:frame_before) { lifetime.frame_after_arguments }
    let(:frame_after) { lifetime.frame_after_call_command }

    let(:ram_before) { { pointers: frame_before.pointers, stack: arguments } }
    let(:pointers_after) { frame_after.pointers }
    let(:saved_pointers_ram) { frame_after.saved_pointers_ram }

    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_jump(function_name) do
        code_writer.write_call function_name, arguments.length
      end
    end

    it 'writes assembly to preserve the caller’s segment pointers' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(saved_pointers_ram)
    end

    it 'writes assembly to set up the callee’s local, argument and stack segment pointers' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(pointers: pointers_after)
    end

    it 'writes assembly to expose the arguments to the callee' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(
        pointers: { argument: pointers_after[:argument] },
        argument: arguments
      )
    end

    it 'writes assembly to transfer control to the callee' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(detector.success)
    end
  end

  describe '#write_return' do
    include EmulationHelper
    include RamMatchers

    let(:arguments) { [1234, 47] }
    let(:return_value) { 1196 }

    let(:frame) {
      StackFrame.new(
        lengths:  { local: 5 },
        pointers: { stack: 310, this: 3010, that: 4010 }
      )
    }
    let(:lifetime) {
      FunctionLifetime.new(
        frame: frame,
        lengths: { argument: arguments.length, local: 3 },
        pointers: { this: 3000, that: 4000 }
      )
    }
    let(:frame_before) { lifetime.frame_after_body }
    let(:frame_after) { lifetime.frame_after_return_command }

    let(:ram_before) { { pointers: frame_before.pointers, stack: [return_value] }.merge(saved_pointers_ram) }
    let(:pointers_after) { frame_after.pointers }
    let(:saved_pointers_ram) { frame_before.saved_pointers_ram }

    let(:detector) { ControlFlowDetector.new(output) }

    before(:example) do
      detector.detect_return(frame_before) do
        code_writer.write_return
      end
    end

    it 'writes assembly to restore the caller’s local, argument, this, that and stack segment pointers' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(pointers: pointers_after)
    end

    it 'writes assembly to expose the return value to the caller' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(
        pointers: { stack: pointers_after[:stack] },
        stack: return_value
      )
    end

    it 'writes assembly to return control to the caller' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(detector.success)
    end
  end

  describe '#write_function' do
    include EmulationHelper
    include RamMatchers

    let(:function_name) { 'myFunction' }
    let(:num_locals) { 3 }

    let(:frame) { StackFrame.new(pointers: { stack: 310 }) }
    let(:lifetime) {
      FunctionLifetime.new(
        frame: frame,
        lengths: { local: num_locals }
      )
    }
    let(:frame_before) { lifetime.frame_after_call_command }
    let(:frame_after) { lifetime.frame_after_function_command }

    let(:ram_before) { { pointers: frame_before.pointers, local: 1.upto(num_locals).entries } }
    let(:pointers_after) { frame_after.pointers }

    before(:example) do
      code_writer.write_function function_name, num_locals
    end

    it 'writes assembly to set up the callee’s local variables' do
      expect(emulation_of(assembly)).to change_ram.from(ram_before).to(
        pointers: { local: pointers_after[:local] },
        local: num_locals.times.map { 0 }
      )
    end

    it 'writes assembly to move the callee’s stack pointer past its local variables' do
      expect(emulation_of(assembly)).to change_ram.
        from(ram_before).to(pointers: { stack: pointers_after[:stack] })
    end
  end

  describe 'modularity' do
    include EmulationHelper
    include RamMatchers

    context 'for conditionals' do
      before(:example) do
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 1
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 2
        code_writer.write_arithmetic 'eq'

        code_writer.write_push_pop Parser::C_PUSH, 'constant', 0
        code_writer.write_arithmetic 'eq'
      end

      it 'writes assembly that uses independent control flow for each conditional' do
        expect(emulation_of(assembly)).to change_ram.from(stack: []).to(stack: -1)
      end
    end

    context 'for static variables' do
      before(:example) do
        code_writer.set_file_name 'first'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 10
        code_writer.write_push_pop Parser::C_POP, 'static', 0
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 20
        code_writer.write_push_pop Parser::C_POP, 'static', 1

        code_writer.set_file_name 'second'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 30
        code_writer.write_push_pop Parser::C_POP, 'static', 0
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 40
        code_writer.write_push_pop Parser::C_POP, 'static', 1

        code_writer.set_file_name 'first'
        code_writer.write_push_pop Parser::C_PUSH, 'static', 0
        code_writer.write_push_pop Parser::C_PUSH, 'static', 1
      end

      it 'writes assembly that uses independent static variables for each file', :pending do
        expect(emulation_of(assembly)).to change_ram.from(stack: []).to(stack: [10, 20])
      end
    end

    context 'for return addresses' do
      include AssemblyHelper

      before(:example) do
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 1
        code_writer.write_call 'function', 0
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 2
        code_writer.write_call 'function', 0
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 3

        output.write finish_code

        code_writer.write_function 'function', 0
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 10
        code_writer.write_return
      end

      it 'writes assembly that uses an independent return address for each call' do
        expect(emulation_of(assembly)).to change_ram.from(stack: []).to(stack: [1, 10, 2, 10, 3])
      end
    end

    context 'for labels' do
      include AssemblyHelper

      before(:example) do
        code_writer.write_call 'first', 0
        code_writer.write_call 'second', 0

        output.write finish_code

        code_writer.write_function 'first', 0
        code_writer.write_goto 'label'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 10
        code_writer.write_return
        code_writer.write_label 'label'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 20
        code_writer.write_return

        code_writer.write_function 'second', 0
        code_writer.write_goto 'label'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 30
        code_writer.write_return
        code_writer.write_label 'label'
        code_writer.write_push_pop Parser::C_PUSH, 'constant', 40
        code_writer.write_return
      end

      it 'writes assembly that uses independent labels for each function', :pending do
        expect(emulation_of(assembly)).to change_ram.from(stack: []).to(stack: [20, 40])
      end
    end
  end

  describe '#close' do
    it 'closes the output' do
      expect(output).to receive(:close)
      code_writer.close
    end
  end
end
