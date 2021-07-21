require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe GatewayResponse do
    subject(:response) { described_class.new(success, 'response message', 'API_RESPONSE_INSTANCE', options) }

    let(:success) { true }
    let(:options) { {} }

    describe '#initialize' do
      describe 'when given option :error_name' do
        let(:options) { { error_name: 'GENERAL ERROR' } }

        it 'sets the error name' do
          expect(response.error_name).to eq('GENERAL ERROR')
        end
      end

      describe 'when given option :authorization' do
        let(:options) { { authorization: 'CAPTURE_ID' } }

        it 'sets the authorization' do
          expect(response.authorization).to eq('CAPTURE_ID')
        end
      end
    end

    describe '#success?' do
      context 'when initialized as a success' do
        let(:success) { true }

        it 'is true' do
          expect(response).to be_success
        end
      end

      context 'when initialized as failure' do
        let(:success) { false }

        it 'is false' do
          expect(response).not_to be_success
        end
      end
    end

    describe '#to_s' do
      it 'returns the message' do
        expect(response.to_s).to eq('response message')
      end
    end

    describe '#avs_result' do
      it 'is an empty hash' do
        expect(response.avs_result).to eq({})
      end
    end

    describe '#cvv_result' do
      it 'is nil' do
        expect(response.cvv_result).to be_nil
      end
    end
  end
end
