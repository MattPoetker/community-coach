# frozen_string_literal: true

module Money
  SYMBOLS = { "GBP" => "£", "USD" => "$", "EUR" => "€", "AUD" => "A$", "CAD" => "C$" }.freeze
  # Currencies without minor units. Charging 100x is a memorable way to learn they exist.
  ZERO_DECIMAL = %w[JPY KRW VND CLP ISK].freeze

  module_function

  def format(cents, currency)
    symbol = SYMBOLS.fetch(currency.to_s.upcase, "")
    if ZERO_DECIMAL.include?(currency.to_s.upcase)
      "#{symbol}#{cents.to_i}"
    else
      whole, part = (cents.to_i.abs).divmod(100)
      formatted = "#{symbol}#{whole.to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
      part.zero? ? formatted : "#{formatted}.#{part.to_s.rjust(2, '0')}"
    end
  end

  def minor_units(currency) = ZERO_DECIMAL.include?(currency.to_s.upcase) ? 1 : 100
end
