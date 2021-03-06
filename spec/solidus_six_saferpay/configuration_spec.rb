require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe Configuration do

    describe '.config' do
      it 'exposes a configurable list of error handlers' do
        expect(described_class).to respond_to(:error_handlers)
      end
    end
  end
end
