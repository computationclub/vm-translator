require 'support/ram_description'

module RamMatchers
  extend RSpec::Matchers::DSL

  DEFAULT_CYCLE_COUNT = 1000

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
      RamDescription.new(ram_description_before).to_ram
    end

    def expected_ram_after
      RamDescription.new(expected_ram_description_after).to_ram
    end
  end
end
