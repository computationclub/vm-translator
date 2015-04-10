class FunctionLifetime
  def initialize(frame:, lengths: {}, pointers: {})
    self.frame    = frame
    self.lengths  = lengths
    self.pointers = pointers
  end

  def frame_after_arguments
    argument_length.times.inject(frame) { |frame| frame.after_push_command }
  end

  def frame_after_call_command
    frame_after_arguments.after_call_command(argument_length: argument_length)
  end

  def frame_after_function_command
    frame_after_call_command.after_function_command(local_length: local_length)
  end

  def frame_after_body
    frame_after_function_command.after_update(pointers: pointers).after_push_command
  end

  def frame_after_return_command
    frame_after_body.after_return_command
  end

  private

  attr_accessor :frame, :lengths, :pointers

  def argument_length
    lengths.fetch(:argument, 0)
  end

  def local_length
    lengths.fetch(:local, 0)
  end
end
