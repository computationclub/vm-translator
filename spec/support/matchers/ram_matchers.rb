module RamMatchers
  extend RSpec::Matchers::DSL

  DEFAULT_CYCLE_COUNT = 1000

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

  matcher :change_ram do
    chain :from, :ram_description_before
    chain :to, :expected_ram_description_after
    chain :in, :explicit_cycle_count
    def cycles; self; end # syntactic sugar

    attr_accessor :actual_ram_after, :matcher

    match do |emulation|
      self.actual_ram_after = emulation.run(ram_before, output_addresses, cycle_count)
      self.matcher = RSpec::Matchers::BuiltIn::Include.new(expected_ram_after)
      matcher.matches?(actual_ram_after)
    end

    failure_message do
      matcher.failure_message
    end

    description do
      "change RAM from #{ram_before} to #{expected_ram_after} in #{cycle_count} cycles"
    end

    diffable

    def expected
      expected_ram_after
    end

    def actual
      actual_ram_after
    end

    private

    def cycle_count
      explicit_cycle_count || DEFAULT_CYCLE_COUNT
    end

    def output_addresses
      (ram_before.keys + expected_ram_after.keys).uniq.sort
    end

    def ram_before
      ram_from_description ram_description_before
    end

    def expected_ram_after
      ram_from_description expected_ram_description_after
    end

    def ram_from_description(ram_description)
      ram_description.map { |segment, values| ram_from_segment_values(segment, Array(values)) }.inject({}, :merge)
    end

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
      SEGMENT_ADDRESS.fetch(segment).upto(Float::INFINITY)
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
end
