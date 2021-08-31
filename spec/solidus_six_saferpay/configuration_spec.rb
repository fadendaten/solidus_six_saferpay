require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe Configuration do
    it 'exposes a configurable list of error handlers' do
      expect(SolidusSixSaferpay.config).to respond_to(:error_handlers)
    end

    it 'allows configuration of the address_name_extractor class' do
      expect(SolidusSixSaferpay.config).to respond_to(:address_name_extractor_class)
    end

    it 'allows configuration for unsafe address name extraction' do
      expect(SolidusSixSaferpay.config).to respond_to(:allow_unsafe_address_name_extraction)
    end

    it 'allows configuration of the payment_initialize_params class' do
      expect(SolidusSixSaferpay.config).to respond_to(:payment_initialize_params_class)
    end

    it 'allows configuration of the line_item_type_deductor class' do
      expect(SolidusSixSaferpay.config).to respond_to(:line_item_type_deductor_class)
    end
  end
end
