require 'support/ram_description'

module ReadabilityHelper
  ADDRESS_NAMES = %i[SP LCL ARG THIS THAT]

  def parse_table(table)
    header, *body = table.split("\n")

    ram_addresses = parse_header(header)

    body.map do |row|
      ram_addresses.zip(parse_row(row)).to_h
    end
  end

  def parse_header(header)
    parse_row(header).map { |h| readable_name(h) }
  end

  def parse_row(row)
    row.split("|")[1..-1].map(&:strip)
  end

  def readable_name(address)
    index = Integer(address.gsub(/[^\d]/, ""))

    name = ADDRESS_NAMES[index]
    name ? "#{address} (#{name})" : address
  end
end
