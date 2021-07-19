require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe ErrorHandler do
    let(:error) { StandardError.new }
    let(:error_handlers) { [] }

    before do
      allow(SolidusSixSaferpay.config).to receive(:error_handlers).and_return(error_handlers)
    end

    describe '.handle' do
      it 'defaults to level :error' do
        expect(Rails.logger).to receive(:error).with(error)
        described_class.handle(error)
      end

      it 'allows for configuring the error level' do
        expect(Rails.logger).to receive(:info).with(error)
        described_class.handle(error, level: :info)
      end

      context 'when any attached handler can not receive our error messages' do
        let(:error_handler1) { double("Handler1", to_s: 'handler1', call: true) }
        let(:error_handler2) { double("Handler2", to_s: 'handler2') }
        let(:error_handler3) { double("Handler3", to_s: 'handler3', call: true) }

        let(:error_handlers) { [error_handler1, error_handler2, error_handler3] }

        before do
          allow(error_handler1).to receive(:respond_to?).with(:call).and_return(true)
          allow(error_handler2).to receive(:respond_to?).with(:call).and_return(false)
          allow(error_handler3).to receive(:respond_to?).with(:call).and_return(true)
        end

        it 'informs about the misconfiguration via Rails logger' do
          expect(Rails.logger).to receive(:warn).with(/ERROR:.*handler2.*/)

          described_class.handle(error)
        end

        it 'skips to the next error handler' do
          expect(error_handler1).to receive(:call).with(error, level: :error)
          expect(error_handler2).not_to receive(:call)
          expect(error_handler3).to receive(:call).with(error, level: :error)

          described_class.handle(error)
        end
      end

      context 'when an attached handler can receive our error messages' do
        let(:error_handler) { double("CustomErrorHandler", call: true) }
        let(:error_handlers) { [error_handler] }

        it 'forwards the error to the error handler' do
          expect(error_handler).to receive(:call).with(error, level: :error)

          described_class.handle(error)
        end
      end
    end
  end
end
