class Parser
  C_ARITHMETIC = Object.new
  C_POP = Object.new
  C_PUSH = Object.new
  C_LABEL = Object.new
  C_GOTO = Object.new
  C_IF = Object.new
  C_FUNCTION = Object.new
  C_CALL = Object.new
  C_RETURN = Object.new

  def initialize(input)
    @lines = split_lines(input)
  end

  def has_more_commands?
    !lines.empty?
  end

  def advance
    @current = lines.shift
  end

  def command_type
    case current.split(' ').first
    when 'pop'
      C_POP
    when 'push'
      C_PUSH
    when 'label'
      C_LABEL
    when 'goto'
      C_GOTO
    when 'if-goto'
      C_IF
    when 'function'
      C_FUNCTION
    when 'call'
      C_CALL
    when 'return'
      C_RETURN
    else
      C_ARITHMETIC
    end
  end

  def arg1
    case command_type
    when C_ARITHMETIC
      current
    else
      current.split[1]
    end
  end

  def arg2
    Integer(current.split[2])
  end

  private

  attr_reader :lines, :current

  def split_lines(input)
    input
      .lines
      .map { |line| line.sub(%r{//.*$}, '').strip }
      .reject(&:empty?)
  end
end
