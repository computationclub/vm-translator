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
    hash.map { |segment, values| ram_from_segment_values(segment, Array(values)) }.inject({}, :merge)
  end

  private

  def ram_from_segment_values(segment, values)
    segment_ram = get_segment_ram(segment, get_numeric_values(values))
    segment_addresses = segment_ram.each_key
    pointer_ram = get_pointer_ram(segment, segment_addresses)

    pointer_ram.merge(segment_ram)
  end

  def get_segment_ram(segment, values)
    Hash[values.zip(get_segment_addresses(segment)).map(&:reverse)]
  end

  def get_segment_addresses(segment)
    get_segment_address(segment).upto(Float::INFINITY)
  end

  def get_segment_address(segment)
    SEGMENT_ADDRESS.fetch(segment)
  end

  def get_numeric_values(values)
    values.map do |value|
      case value
      when Numeric
        value
      else
        value ? -1 : 0
      end
    end
  end

  def get_pointer_ram(segment, addresses)
    case segment
    when :stack, :local, :argument, :this, :that
      { POINTER_ADDRESS.fetch(segment) => get_pointer_address(segment, addresses) }
    else
      {}
    end
  end

  def get_pointer_address(segment, addresses)
    case segment
    when :stack
      addresses.max.succ
    else
      addresses.min
    end
  end
end
