require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe ErrorHandler do
    let(:error_handlers) { [] }

    let(:error_handler_class) do
      Class.new do
        def initialize(name)
          @name = name
        end

        def to_s
          @name
        end

        def call(error, _level: :error)
          error
        end
      end
    end

    before do
      allow(SolidusSixSaferpay.config).to receive(:error_handlers).and_return(error_handlers)
    end

    describe '.handle' do
      it 'defaults to level :error' do
        allow(Rails.logger).to receive(:error)

        described_class.handle(StandardError.new)

        expect(Rails.logger).to have_received(:error).with(StandardError.new)
      end

      it 'allows for configuring the error level' do
        allow(Rails.logger).to receive(:info)

        described_class.handle(StandardError.new, level: :info)

        expect(Rails.logger).to have_received(:info).with(StandardError.new)
      end

      context 'when any attached handler can not receive our error messages' do
        let(:misconfigured_error_handler_class) do
          Class.new do
            def initialize(name)
              @name = name
            end

            def to_s
              @name
            end
          end
        end

        let(:error_handler2) { misconfigured_error_handler_class.new('handler2') }
        let(:error_handler3) { error_handler_class.new('handler3') }

        let(:error_handlers) { [error_handler2, error_handler3] }

        it 'informs about the misconfiguration via Rails logger' do
          allow(Rails.logger).to receive(:warn)
          described_class.handle(StandardError.new)

          expect(Rails.logger).to have_received(:warn).with(/ERROR:.*handler2.*/)
        end

        it 'does not fail when calling a misconfigured handler' do
          allow(error_handler2).to receive(:call).and_call_original

          described_class.handle(StandardError.new)

          expect(error_handler2).to have_received(:call)
        end

        it 'calls other error handlers after the misconfigured one' do
          allow(error_handler3).to receive(:call)

          described_class.handle(StandardError.new)

          expect(error_handler3).to have_received(:call).with(StandardError.new, level: :error)
        end
      end

      context 'when an attached handler can receive our error messages' do
        let(:error_handler) { error_handler_class.new('handler') }
        let(:error_handlers) { [error_handler] }

        it 'forwards the error to the error handler' do
          allow(error_handler).to receive(:call)

          described_class.handle(StandardError.new)

          expect(error_handler).to have_received(:call).with(StandardError.new, level: :error)
        end
      end
    end
  end
end
