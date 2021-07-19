require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe GatewayResponse do
    subject { described_class.new(success, message, api_response, options) }

    let(:success) { true }
    let(:message) { double('message') }
    let(:api_response) { double('API response') }
    let(:options) { {} }

    describe '#initialize' do
      let(:error_name) { double("error_name") }
      let(:authorization) { double("authorization") }

      describe 'when given option :error_name' do
        let(:options) { { error_name: error_name } }

        it 'sets the error name' do
          expect(subject.error_name).to eq(error_name)
        end
      end

      describe 'when given option :authorization' do
        let(:options) { { authorization: authorization } }

        it 'sets the authorization' do
          expect(subject.authorization).to eq(authorization)
        end
      end
    end

    describe '#success?' do
      context 'when initialized as a success' do
        let(:success) { true }

        it 'is true' do
          expect(subject).to be_success
        end
      end

      context 'when initialized as failure' do
        let(:success) { false }

        it 'is false' do
          expect(subject).not_to be_success
        end
      end
    end

    describe '#to_s' do
      it 'returns the message' do
        expect(subject.to_s).to eq(message)
      end
    end

    describe '#avs_result' do
      it 'is an empty hash' do
        expect(subject.avs_result).to eq({})
      end
    end

    describe '#cvv_result' do
      it 'is nil' do
        expect(subject.cvv_result).to be_nil
      end
    end
  end
end
