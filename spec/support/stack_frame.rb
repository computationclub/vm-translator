class StackFrame
  def initialize(parent: nil, lengths: {}, pointers:)
    self.parent         = parent
    self.lengths        = lengths
    self.given_pointers = pointers
  end

  def pointers
    computed_pointers
  end

  def saved_pointers_ram
    Hash[saved_pointers.map { |name, value| [saved_pointer_address(name), value] }]
  end

  def after_update(parent: self.parent, lengths: {}, pointers: {})
    self.class.new \
      parent:   parent,
      lengths:  self.lengths.merge(lengths),
      pointers: self.pointers.merge(pointers)
  end

  def after_call_command(argument_length:)
    after_update \
      parent: self,
      lengths: {
        local:    local_length = 0,
        argument: argument_length,
        stack:    stack_length = 0
      },
      pointers: {
        stack: stack_address + (saved_pointers_length + local_length + stack_length)
      }
  end

  def after_function_command(local_length:)
    after_update lengths: { local: local_length }, pointers: { stack: stack_address + local_length }
  end

  def after_push_command
    after_update lengths: { stack: stack_length + 1 }, pointers: { stack: stack_address + 1 }
  end

  def after_pop_command
    after_update lengths: { stack: stack_length - 1 }, pointers: { stack: stack_address - 1 }
  end

  def after_return_command
    argument_length.times.inject(parent) { |frame| frame.after_pop_command }.after_push_command
  end

  def saved_pointer_address(pointer)
    saved_pointers_address + SAVED_POINTER_NAMES.index(pointer)
  end

  protected

  attr_accessor :parent, :lengths, :given_pointers

  private

  SAVED_POINTER_NAMES = %i{return local argument this that}

  def argument_length
    lengths.fetch(:argument, 0)
  end

  def saved_pointers_length
    SAVED_POINTER_NAMES.length
  end

  def local_length
    lengths.fetch(:local, 0)
  end

  def stack_length
    lengths.fetch(:stack, 0)
  end

  def argument_address
    saved_pointers_address - argument_length
  end

  def saved_pointers_address
    local_address - saved_pointers_length
  end

  def local_address
    stack_address - (local_length + stack_length)
  end

  def stack_address
    given_pointers.fetch(:stack)
  end

  def computed_pointers
    given_pointers.merge local: local_address, argument: argument_address
  end

  def saved_pointers
    parent.pointers.select { |name| SAVED_POINTER_NAMES.include?(name) }
  end
end
