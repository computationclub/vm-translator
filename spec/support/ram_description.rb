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
    hash.keys.map { |segment| ram_from_segment_values(segment) }.inject({}, :merge)
  end

  private

  def ram_from_segment_values(segment)
    segment_ram = get_segment_contents_ram(segment)
    pointer_ram = get_pointer_ram(segment)

    pointer_ram.merge(segment_ram)
  end

  def get_segment_values(segment)
    Array(hash.fetch(segment)).map(&method(:value_to_number))
  end

  def get_segment_contents_ram(segment)
    values = get_segment_values(segment)
    addresses = get_segment_addresses(segment)

    Hash[values.zip(addresses).map(&:reverse)]
  end

  def get_segment_addresses(segment)
    get_segment_address(segment).upto(Float::INFINITY)
  end

  def get_segment_address(segment)
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

  def get_pointer_ram(segment)
    case segment
    when :stack, :local, :argument, :this, :that
      { POINTER_ADDRESS.fetch(segment) => get_pointer_address(segment) }
    else
      {}
    end
  end

  def get_pointer_address(segment)
    get_segment_address(segment) + get_pointer_offset(segment)
  end

  def get_pointer_offset(segment)
    case segment
    when :stack
      Array(hash.fetch(:stack, [])).length
    else
      0
    end
  end
end
