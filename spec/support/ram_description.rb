class RamDescription < Struct.new(:hash)
  SEGMENT_POINTER_ADDRESS = {
    stack:    0,
    local:    1,
    argument: 2,
    this:     3,
    that:     4
  }

  DEFAULT_SEGMENT_POINTER = {
    temp:     5,
    static:   16,
    stack:    256,
    local:    300,
    argument: 400,
    this:     3000,
    that:     3010,
    pointer:  SEGMENT_POINTER_ADDRESS[:this]
  }

  def to_ram
    segments.map { |segment| segment_ram(segment) }.inject({}, :merge)
  end

  private

  def segments
    hash.keys
  end

  def segment_ram(segment)
    case segment
    when Numeric
      segment_contents_ram(segment)
    else
      segment_ram = segment_contents_ram(segment)
      pointer_ram = segment_pointer_ram(segment)

      pointer_ram.merge(segment_ram)
    end
  end

  def segment_contents_ram(segment)
    contents = segment_contents(segment)
    addresses = segment_addresses(segment)

    Hash[addresses.zip(contents)]
  end

  def segment_contents(segment)
    Array(hash.fetch(segment)).map(&method(:value_to_number))
  end

  def value_to_number(value)
    case value
    when Numeric
      value
    else
      value ? -1 : 0
    end
  end

  def segment_addresses(segment)
    base_address = segment_base_address(segment)
    size = segment_contents(segment).length

    base_address...(base_address + size)
  end

  def segment_base_address(segment)
    segment_pointer_address(segment) - segment_pointer_offset(segment)
  end

  def segment_pointer_ram(segment)
    case segment
    when :stack, :local, :argument, :this, :that
      { SEGMENT_POINTER_ADDRESS.fetch(segment) => segment_pointer_address(segment) }
    else
      {}
    end
  end

  def segment_pointer_address(segment)
    segment_base_address =
      case segment
      when Numeric
        segment
      else
        DEFAULT_SEGMENT_POINTER.fetch(segment)
      end

    segment_base_address + segment_pointer_offset(segment)
  end

  def segment_pointer_offset(segment)
    case segment
    when :stack
      segment_contents(segment).length
    else
      0
    end
  end
end
