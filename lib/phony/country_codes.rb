module Phony

  EMPTY_STRING = ''

  # Handles determining the correct national code handler.
  #
  class CountryCodes

    attr_reader   :countries
    attr_accessor :international_absolute_format, :international_relative_format, :national_format

    def self.instance
      @instance ||= new
    end

    # Get the Country object for the given CC.
    #
    def [] cc
      countries[cc.size][cc]
    end

    # Clean number of all non-numeric characters, initial zeros or (0.
    #
    @@basic_cleaning_pattern = /\A00?|\(0|\D/
    # Clean number of all non-numeric characters, initial zeros or (0 and return it.
    #
    def clean number
      clean! number && number.dup
    end
    # Clean number of all non-numeric characters, initial zeros or (0 and return a copy.
    #
    def clean! number
      number.gsub!(@@basic_cleaning_pattern, EMPTY_STRING) || number
    end

    # Adds the country code to the front
    # if it does not already start with it.
    #
    # Note: This won't be correct in some cases, but it is the best we can do.
    #
    def countrify number, cc
      countrify!(number, cc) || number
    end
    def countrify! number, cc
      number.sub!(/\A/, cc) # @countrify_regex, @cc
    end

    # 00 for the standard international call prefix.
    # http://en.wikipedia.org/wiki/List_of_international_call_prefixes
    #
    # We can't know from what country that person was calling, so we
    # can't remove the intl' call prefix.
    #
    # We remove:
    #  * 0 or 00 at the very beginning.
    #  * (0) anywhere.
    #  * Non-digits.
    #
    def normalize number, options = {}
      country = if cc = options[:cc]
        self[cc]
      else
        clean! number
        country, cc, number = split_cc number
        country
      end
      number = country.normalize number
      countrify! number, cc
    end

    # Splits this number into cc, ndc and locally split number parts.
    #
    def split number
      _, *cc_split_rest = internal_split number
      cc_split_rest
    end
    
    def internal_split number
      country, cc, rest = split_cc number
      [country, cc, *country.split(rest)]
    end

    def format number, options = {}
      country, _, national = split_cc number
      country.format national, options
    end
    alias formatted format

    #
    #
    def service? number
      country_for(number).service? rest
    end
    def mobile? number
      country_for(number).mobile? rest
    end
    def landline? number
      country_for(number).landline? rest
    end
    
    #
    #
    def country_for number
      country, _ = split_cc number
      country
    end

    # Is the given number a vanity number?
    #
    def vanity? number
      country, _, national = split_cc number
      country.vanity? national
    end
    # Converts a vanity number into a normalized E164 number.
    #
    def vanity_to_number vanity_number
      country, cc, national = split_cc vanity_number
      "#{cc}#{country.vanity_to_number(national)}"
    end

    # TODO Rename, doc.
    #
    def split_cc rest
      cc = ''
      1.upto(3) do |i|
        cc << rest.slice!(0..0)
        country = countries[i][cc]
        return [country, cc, rest] if country
      end
      # This line is never reached as CCs are in prefix code.
    end

    # TODO Doc.
    #
    def plausible? number, hints = {}
      normalized = clean number

      # False if it fails the basic check.
      #
      return false unless (4..15) === normalized.size

      country, cc, rest = split_cc normalized

      # Country code plausible?
      #
      cc_needed = hints[:cc]
      return false if cc_needed && !(cc_needed === cc)

      # Country specific tests.
      #
      country.plausible? rest, hints
    rescue StandardError
      return false
    end

    # Add the given country to the mapping under the
    # given country code.
    #
    def add country_code, country
      country_code = country_code.to_s
      optimized_country_code_access = country_code.size

      @countries ||= {}
      @countries[optimized_country_code_access] ||= {}
      @countries[optimized_country_code_access][country_code] = country
    end

  end

end
