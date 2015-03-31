class RamDescription < Struct.new(:hash)
  POINTER_ADDRESS = {
    stack:    0,
    local:    1,
    argument: 2,
    this:     3,
    that:     4
  }

  SEGMENT_ADDRESS = {
    temp:     5,
    static:   16,
    stack:    256,
    local:    300,
    argument: 400,
    this:     3000,
    that:     3010,
    pointer:  POINTER_ADDRESS[:this]
  }

  def to_ram
    segments.map { |segment| segment_ram(segment) }.inject({}, :merge)
  end

  private

  def segments
    hash.keys
  end

  def segment_ram(segment)
    segment_ram = segment_contents_ram(segment)
    pointer_ram = segment_pointer_ram(segment)

    pointer_ram.merge(segment_ram)
  end

  def segment_contents(segment)
    Array(hash.fetch(segment)).map(&method(:value_to_number))
  end

  def segment_contents_ram(segment)
    contents = segment_contents(segment)
    addresses = segment_addresses(segment)

    Hash[contents.zip(addresses).map(&:reverse)]
  end

  def segment_addresses(segment)
    segment_address(segment).upto(Float::INFINITY)
  end

  def segment_address(segment)
    SEGMENT_ADDRESS.fetch(segment)
  end

  def value_to_number(value)
    case value
    when Numeric
      value
    else
      value ? -1 : 0
    end
  end

  def segment_pointer_ram(segment)
    case segment
    when :stack, :local, :argument, :this, :that
      { POINTER_ADDRESS.fetch(segment) => pointer_address(segment) }
    else
      {}
    end
  end

  def pointer_address(segment)
    segment_address(segment) + pointer_offset(segment)
  end

  def pointer_offset(segment)
    case segment
    when :stack
      Array(hash.fetch(:stack, [])).length
    else
      0
    end
  end
end
