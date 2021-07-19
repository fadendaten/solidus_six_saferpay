require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe Configuration do

    it 'exposes a configurable list of error handlers' do
      expect(SolidusSixSaferpay.config).to respond_to(:error_handlers)
    end
  end
end
