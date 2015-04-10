require 'support/helpers/label_helper'

module AssemblyHelper
  include LabelHelper

  def finish_code
    finish_label = fresh_label

    <<-eop
      @#{finish_label}
      (#{finish_label})
      0;JMP
    eop
  end

  def jump_and_label_code(label = fresh_label)
    [
      %Q{
        @#{label}
        0;JMP
      },
      %Q{
        (#{label})
      }
    ]
  end

  def overwrite_saved_pointers_code(frame, saved_pointers)
    saved_pointers.map { |name, address|
      <<-eop
        @#{address}
        D=A
        @#{frame.saved_pointer_address(name)}
        M=D
      eop
    }.join
  end
end
