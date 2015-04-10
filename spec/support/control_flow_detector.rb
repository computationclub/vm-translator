require 'support/helpers/assembly_helper'
require 'support/helpers/label_helper'

ControlFlowDetector = Struct.new(:output) do
  include AssemblyHelper
  include LabelHelper

  def detect_jump(destination_label)
    assembly_jump_code, assembly_label_code = jump_and_label_code
    _, destination_label_code = jump_and_label_code(destination_label)

    output.write assembly_jump_code
    output.write destination_label_code
    output.write success_code
    output.write finish_code
    output.write assembly_label_code
    yield
  end

  def detect_return(frame)
    saved_pointers = { return: fresh_label }
    set_return_address_code = overwrite_saved_pointers_code(frame, saved_pointers)

    output.write set_return_address_code

    detect_jump saved_pointers[:return] do
      yield
    end
  end

  def detect_label(label)
    jump_code, _ = jump_and_label_code(label_outside_function(label))

    output.write jump_code
    output.write finish_code
    yield
    output.write success_code
  end

  def detect_goto(label)
    _, label_code = jump_and_label_code(label_outside_function(label))

    yield
    output.write finish_code
    output.write label_code
    output.write success_code
  end

  def success
    { SUCCESS_ADDRESS => SUCCESS_VALUE }
  end

  private

  SUCCESS_ADDRESS = 13 # use R13 to track success
  SUCCESS_VALUE = 9999 # arbitrary magic number

  def success_code
    <<-eop
      @#{SUCCESS_VALUE}
      D=A
      @#{SUCCESS_ADDRESS}
      M=D
    eop
  end
end
