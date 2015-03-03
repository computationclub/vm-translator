require 'code_writer'
require 'parser'
require 'stringio'
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

  describe '#close' do
    it 'closes the output' do
      expect(output).to receive(:close)
      code_writer.close
    end
  end
end
