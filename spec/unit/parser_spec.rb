require 'parser'

RSpec.describe Parser do
  BASIC_TEST_PROGRAM = <<-eop
    // This file is part of www.nand2tetris.org
    // and the book "The Elements of Computing Systems"
    // by Nisan and Schocken, MIT Press.
    // File name: projects/07/MemoryAccess/BasicTest/BasicTest.vm

    // Executes pop & push commands using the virtual memory segments.
    push constant 10
    pop local 0
    push constant 21
    push constant 22
    pop argument 2
    pop argument 1
    push constant 36
    pop this 6
    push constant 42
    push constant 45
    pop that 5
    pop that 2
    push constant 510
    pop temp 6
    push local 0
    push that 5
    add
    push argument 1
    sub
    push this 6
    push this 6
    add
    sub
    push temp 6
    add
  eop

  subject(:parser) { Parser.new(input) }

  describe '#has_more_commands?' do
    context 'when there are more commands in the input' do
      let(:input) { BASIC_TEST_PROGRAM }

      it 'returns true' do
        expect(parser.has_more_commands?).to be_truthy
      end
    end

    context 'when there are no more commands in the input' do
      context 'because the input is empty' do
        let(:input) { '' }

        it 'returns false' do
          expect(parser.has_more_commands?).to be_falsy
        end
      end

      context 'because the input contains only whitespace' do
        let(:input) { "  \n  " }

        it 'returns false' do
          expect(parser.has_more_commands?).to be_falsy
        end
      end

      context 'because the input contains only comments' do
        let(:input) { '// a comment' }

        it 'returns false' do
          expect(parser.has_more_commands?).to be_falsy
        end
      end

      context 'because the input contains only whitespace and comments' do
        let(:input) { "  \n  // a comment\n  // another comment\n  " }

        it 'returns false' do
          expect(parser.has_more_commands?).to be_falsy
        end
      end
    end
  end

  describe '#advance' do
    let(:input) { BASIC_TEST_PROGRAM }

    context 'when called fewer times than there are commands' do
      before(:example) do
        10.times do
          parser.advance
        end
      end

      it 'leaves more commands' do
        expect(parser.has_more_commands?).to be_truthy
      end
    end

    context 'when called as many times as there are commands' do
      before(:example) do
        25.times do
          parser.advance
        end
      end

      it 'leaves no more commands' do
        expect(parser.has_more_commands?).to be_falsy
      end
    end

    context 'with interleaved comments' do
      let(:input) do
        <<-eop
          push constant 7
          // An interleaved comment
          push constant 8
          // An interleaved comment
          add
        eop
      end

      context 'when called fewer times than there are commands' do
        before(:example) do
          2.times do
            parser.advance
          end
        end

        it 'leaves more commands' do
          expect(parser.has_more_commands?).to be_truthy
        end
      end

      context 'when called as many times as there are commands' do
        before(:example) do
          3.times do
            parser.advance
          end
        end

        it 'leaves no more commands' do
          expect(parser.has_more_commands?).to be_falsy
        end
      end
    end
  end

  describe '#command_type' do
    before(:example) do
      parser.advance
    end

    {
      'add'                     => :C_ARITHMETIC,
      'sub'                     => :C_ARITHMETIC,
      'neg'                     => :C_ARITHMETIC,
      'eq'                      => :C_ARITHMETIC,
      'gt'                      => :C_ARITHMETIC,
      'lt'                      => :C_ARITHMETIC,
      'and'                     => :C_ARITHMETIC,
      'or'                      => :C_ARITHMETIC,
      'not'                     => :C_ARITHMETIC,
      'pop static 8'            => :C_POP,
      'push constant 57'        => :C_PUSH,
      'label LOOP_START'        => :C_LABEL,
      'goto WHILE'              => :C_GOTO,
      'if-goto COMPUTE_ELEMENT' => :C_IF,
      'function Sys.add12 3'    => :C_FUNCTION,
      'call Main.fibonacci 1'   => :C_CALL,
      'return'                  => :C_RETURN
    }.each do |command, type|
      context "when the current command is #{command}" do
        let(:input) { command }

        it "returns #{type}" do
          expect(parser.command_type).to eq Parser.const_get(type)
        end
      end
    end
  end

  describe '#arg1' do
    before(:example) do
      parser.advance
    end

    context 'when the current command is an arithmetic command' do
      let(:input) { 'neg' }

      it 'returns the command itself' do
        expect(parser.arg1).to eq 'neg'
      end
    end

    context 'when the current command is a push' do
      let(:input) { 'push constant 57' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'constant'
      end
    end

    context 'when the current command is a pop' do
      let(:input) { 'pop static 8' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'static'
      end
    end

    context 'when the current command is a label' do
      let(:input) { 'label LOOP_START' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'LOOP_START'
      end
    end

    context 'when the current command is a goto' do
      let(:input) { 'goto WHILE' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'WHILE'
      end
    end

    context 'when the current command is an if-goto' do
      let(:input) { 'if-goto COMPUTE_ELEMENT' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'COMPUTE_ELEMENT'
      end
    end

    context 'when the current command is a function definition' do
      let(:input) { 'function Sys.add12 3' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'Sys.add12'
      end
    end

    context 'when the current command is a function call' do
      let(:input) { 'call Main.fibonacci 1' }

      it 'returns the first argument' do
        expect(parser.arg1).to eq 'Main.fibonacci'
      end
    end
  end

  describe '#arg2' do
    before(:example) do
      parser.advance
    end

    context 'when the current command is a push' do
      let(:input) { 'push constant 57' }

      it 'returns the second argument' do
        expect(parser.arg2).to eq 57
      end
    end

    context 'when the current command is a pop' do
      let(:input) { 'pop static 8' }

      it 'returns the second argument' do
        expect(parser.arg2).to eq 8
      end
    end

    context 'when the current command is a function definition' do
      let(:input) { 'function Sys.add12 3' }

      it 'returns the second argument' do
        expect(parser.arg2).to eq 3
      end
    end

    context 'when the current command is a function call' do
      let(:input) { 'call Main.fibonacci 1' }

      it 'returns the second argument' do
        expect(parser.arg2).to eq 1
      end
    end
  end
end
