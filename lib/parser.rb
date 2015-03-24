class Parser
  C_ARITHMETIC = Object.new
  C_POP = Object.new
  C_PUSH = Object.new

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
    if current.start_with? 'pop'
      C_POP
    elsif current.start_with? 'push'
      C_PUSH
    else
      C_ARITHMETIC
    end
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
