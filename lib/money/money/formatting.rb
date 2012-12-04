# encoding: UTF-8
class Money
  module Formatting
    FORMATS = {
      :default => :to_default_s
    }

    if Object.const_defined?("I18n")
      def thousands_separator
        if self.class.use_i18n
          I18n.t(
            :"number.currency.format.delimiter",
            :default => I18n.t(
              :"number.format.delimiter",
              :default => (currency.thousands_separator || ",")
            )
          )
        else
          currency.thousands_separator || ","
        end
      end
    else
      def thousands_separator
        currency.thousands_separator || ","
      end
    end
    alias :delimiter :thousands_separator


    if Object.const_defined?("I18n")
      def decimal_mark
        if self.class.use_i18n
          I18n.t(
            :"number.currency.format.separator",
            :default => I18n.t(
              :"number.format.separator",
              :default => (currency.decimal_mark || ".")
            )
          )
        else
          currency.decimal_mark || "."
        end
      end
    else
      def decimal_mark
        currency.decimal_mark || "."
      end
    end
    alias :separator :decimal_mark

    def symbol_position
      currency_symbol_position = currency.symbol_first? ? :before : :after
      if Object.const_defined?("I18n") && self.class.use_i18n
        begin
          I18n.t!(:"number.currency.format.symbol_position").to_sym
        rescue I18n::MissingTranslationData
          currency_symbol_position
        end
      else
        currency_symbol_position
      end
    end

    # Creates a formatted price string according to several rules.
    #
    # @param [Hash] *rules The options used to format the string.
    #
    # @return [String]
    #
    # @option *rules [Boolean, String] :display_free (false) Whether a zero
    #  amount of money should be formatted of "free" or as the supplied string.
    #
    # @example
    #   Money.us_dollar(0).format(:display_free => true)     #=> "free"
    #   Money.us_dollar(0).format(:display_free => "gratis") #=> "gratis"
    #   Money.us_dollar(0).format                            #=> "$0.00"
    #
    # @option *rules [Boolean] :with_currency (false) Whether the currency name
    #  should be appended to the result string.
    #
    # @example
    #   Money.ca_dollar(100).format => "$1.00"
    #   Money.ca_dollar(100).format(:with_currency => true) #=> "$1.00 CAD"
    #   Money.us_dollar(85).format(:with_currency => true)  #=> "$0.85 USD"
    #
    # @option *rules [Boolean] :no_cents (false) Whether cents should be omitted.
    #
    # @example
    #   Money.ca_dollar(100).format(:no_cents => true) #=> "$1"
    #   Money.ca_dollar(599).format(:no_cents => true) #=> "$5"
    #
    # @option *rules [Boolean] :no_cents_if_whole (false) Whether cents should be
    #  omitted if the cent value is zero
    #
    # @example
    #   Money.ca_dollar(10000).format(:no_cents_if_whole => true) #=> "$100"
    #   Money.ca_dollar(10034).format(:no_cents_if_whole => true) #=> "$100.34"
    #
    # @option *rules [Boolean, String, nil] :symbol (true) Whether a money symbol
    #  should be prepended to the result string. The default is true. This method
    #  attempts to pick a symbol that's suitable for the given currency.
    #
    # @example
    #   Money.new(100, "USD") #=> "$1.00"
    #   Money.new(100, "GBP") #=> "£1.00"
    #   Money.new(100, "EUR") #=> "€1.00"
    #
    #   # Same thing.
    #   Money.new(100, "USD").format(:symbol => true) #=> "$1.00"
    #   Money.new(100, "GBP").format(:symbol => true) #=> "£1.00"
    #   Money.new(100, "EUR").format(:symbol => true) #=> "€1.00"
    #
    #   # You can specify a false expression or an empty string to disable
    #   # prepending a money symbol.§
    #   Money.new(100, "USD").format(:symbol => false) #=> "1.00"
    #   Money.new(100, "GBP").format(:symbol => nil)   #=> "1.00"
    #   Money.new(100, "EUR").format(:symbol => "")    #=> "1.00"
    #
    #   # If the symbol for the given currency isn't known, then it will default
    #   # to "¤" as symbol.
    #   Money.new(100, "AWG").format(:symbol => true) #=> "¤1.00"
    #
    #   # You can specify a string as value to enforce using a particular symbol.
    #   Money.new(100, "AWG").format(:symbol => "ƒ") #=> "ƒ1.00"
    #
    #   # You can specify a indian currency format
    #   Money.new(10000000, "INR").format(:south_asian_number_formatting => true) #=> "1,00,000.00"
    #   Money.new(10000000).format(:south_asian_number_formatting => true) #=> "$1,00,000.00"
    #
    # @option *rules [Boolean, String, nil] :decimal_mark (true) Whether the
    #  currency should be separated by the specified character or '.'
    #
    # @example
    #   # If a string is specified, it's value is used.
    #   Money.new(100, "USD").format(:decimal_mark => ",") #=> "$1,00"
    #
    #   # If the decimal_mark for a given currency isn't known, then it will default
    #   # to "." as decimal_mark.
    #   Money.new(100, "FOO").format #=> "$1.00"
    #
    # @option *rules [Boolean, String, nil] :thousands_separator (true) Whether
    #  the currency should be delimited by the specified character or ','
    #
    # @example
    #   # If false is specified, no thousands_separator is used.
    #   Money.new(100000, "USD").format(:thousands_separator => false) #=> "1000.00"
    #   Money.new(100000, "USD").format(:thousands_separator => nil)   #=> "1000.00"
    #   Money.new(100000, "USD").format(:thousands_separator => "")    #=> "1000.00"
    #
    #   # If a string is specified, it's value is used.
    #   Money.new(100000, "USD").format(:thousands_separator => ".") #=> "$1.000.00"
    #
    #   # If the thousands_separator for a given currency isn't known, then it will
    #   # default to "," as thousands_separator.
    #   Money.new(100000, "FOO").format #=> "$1,000.00"
    #
    # @option *rules [Boolean] :html (false) Whether the currency should be
    #  HTML-formatted. Only useful in combination with +:with_currency+.
    #
    # @example
    #   s = Money.ca_dollar(570).format(:html => true, :with_currency => true)
    #   s #=>  "$5.70 <span class=\"currency\">CAD</span>"
    def format(*rules)
      # support for old format parameters
      rules = normalize_formatting_rules(rules)
      rules = localize_formatting_rules(rules)

      if fractional == 0
        if rules[:display_free].respond_to?(:to_str)
          return rules[:display_free]
        elsif rules[:display_free]
          return "free"
        end
      end

      symbol_value =
        if rules.has_key?(:symbol)
          if rules[:symbol] === true
            symbol
          elsif rules[:symbol]
            rules[:symbol]
          else
            ""
          end
        elsif rules[:html]
          currency.html_entity == '' ? currency.symbol : currency.html_entity
        else
          symbol
        end

      formatted = rules[:no_cents] ? "#{self.to_s.to_i}" : self.to_s

      if rules[:no_cents_if_whole] && cents % currency.subunit_to_unit == 0
        formatted = "#{self.to_s.to_i}"
      end

      # raise symbol_position.inspect

      symbol_position_value =
        if rules.has_key?(:symbol_position)
          rules[:symbol_position]
        else
          symbol_position
        end

      if symbol_value && !symbol_value.empty?
        formatted = if symbol_position_value == :before
          "#{symbol_value}#{formatted}"
        else
          symbol_space = rules[:symbol_after_without_space] ? "" : " "
          "#{formatted}#{symbol_space}#{symbol_value}"
        end
      end

      if rules.has_key?(:decimal_mark) && rules[:decimal_mark] &&
        rules[:decimal_mark] != decimal_mark
        formatted.sub!(decimal_mark, rules[:decimal_mark])
      end

      thousands_separator_value = thousands_separator
      # Determine thousands_separator
      if rules.has_key?(:thousands_separator)
        thousands_separator_value = rules[:thousands_separator] || ''
      end

      # Apply thousands_separator
      formatted.gsub!(regexp_format(formatted, rules, decimal_mark), "\\1#{thousands_separator_value}")

      if rules[:with_currency]
        formatted << " "
        formatted << '<span class="currency">' if rules[:html]
        formatted << currency.to_s
        formatted << '</span>' if rules[:html]
      end
      formatted
    end

    # Returns the string representation of money. An optional format may be
    # specified.
    # Specify custom formats by assigning them to Money::Formatting::FORMATS.
    #
    # @param [Proc, Symbol, Hash] format Which formatter should be used
    #
    # @return [String]
    #
    # @example
    #   Money.ca_dollar(100).to_s         #=> "1.00"
    #   Money.ca_dollar(100).to_s(:short) #=> "$1"
    def to_s(format = :default)
      locale    = Object.const_defined?("I18n") ? I18n.locale : locale
      formatter = ::Money::Formatting::FORMATS[format]
      formatter = formatter[locale] if locale && formatter.is_a?(Hash) && formatter.has_key?(locale)
      case formatter
      when Proc
        formatter.call(self).to_s
      when Symbol
        __send__(formatter)
      when Hash
        format(formatter)
      else
        self.format # what else could it be?
      end
    end
    alias_method :to_formatted_s, :to_s

    # Returns the amount of money as a string.
    #
    # @return [String]
    #
    # @example
    #   Money.ca_dollar(100).to_s #=> "1.00"
    def to_default_s
      unit, subunit = fractional().abs.divmod(currency.subunit_to_unit)

      unit_str       = ""
      subunit_str    = ""
      fraction_str   = ""

      if self.class.infinite_precision
        subunit, fraction = subunit.divmod(BigDecimal("1"))

        unit_str       = unit.to_i.to_s
        subunit_str    = subunit.to_i.to_s
        fraction_str   = fraction.to_s("F")[2..-1] # want fractional part "0.xxx"

        fraction_str = "" if fraction_str =~ /^0+$/
      else
        unit_str, subunit_str = unit.to_s, subunit.to_s
      end

      absolute_str = if currency.decimal_places == 0
        if fraction_str == ""
          unit_str
        else
          "#{unit_str}#{decimal_mark}#{fraction_str}"
        end
      else
        # need to pad subunit to right position,
        # for example 1 usd 3 cents should be 1.03 not 1.3
        subunit_str.insert(0, '0') while subunit_str.length < currency.decimal_places

        "#{unit_str}#{decimal_mark}#{subunit_str}#{fraction_str}"
      end

      absolute_str.tap do |str|
        str.insert(0, "-") if fractional() < 0
      end
    end

    private

    # Cleans up formatting rules.
    #
    # @param [Hash]
    #
    # @return [Hash]
    def normalize_formatting_rules(rules)
      if rules.size == 0
        rules = {}
      elsif rules.size == 1
        rules = rules.pop
        rules = { rules => true } if rules.is_a?(Symbol)
      end
      if !rules.include?(:decimal_mark) && rules.include?(:separator)
        rules[:decimal_mark] = rules[:separator]
      end
      if !rules.include?(:thousands_separator) && rules.include?(:delimiter)
        rules[:thousands_separator] = rules[:delimiter]
      end
      rules
    end
  end

  def regexp_format(formatted, rules, decimal_mark)
    regexp_decimal = Regexp.escape(decimal_mark)
    if rules[:south_asian_number_formatting]
      /(\d+?)(?=(\d\d)+(\d)(?:\.))/
    else
      if formatted =~ /#{regexp_decimal}/
        /(\d)(?=(?:\d{3})+(?:#{regexp_decimal}))/
      else
        /(\d)(?=(?:\d{3})+(?:[^\d]{1}|$))/
      end
    end
  end

  def localize_formatting_rules(rules)
    if currency.iso_code == "JPY" && I18n.locale == :ja
      rules[:symbol] = "円"
      rules[:symbol_position] = :after
      rules[:symbol_after_without_space] = true
    end
    rules
  end
end
