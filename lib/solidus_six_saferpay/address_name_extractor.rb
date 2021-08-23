module SolidusSixSaferpay
  class AddressNameExtractor
    attr_reader :address_name

    def initialize(address)
      @address_name = address_name(address)
    end

    def first_name
      @address_name.first_name
    end
    alias_method :firstname, :first_name

    def last_name
      @address_name.last_name
    end
    alias_method :lastname, :last_name

    private

    def address_name(address)
      if address.respond_to?(:first_name)
        Spree::Address::Name.new(address.first_name, address.last_name)
      elsif address.respond_to?(:firstname)
        Spree::Address::Name.new(address.first_name, address.last_name)
      else
        if SolidusSixSaferpay.config.allow_unsafe_address_name_extraction
          Spree::Address::Name.new(address.name)
        else
          raise "Unable to safely extract first- and lastname from address"
        end
      end
    end
  end
end
