RSpec.shared_examples 'process_authorized_payment' do
  before do
    allow(SolidusSixSaferpay::Gateway).to receive(:new).and_return(instance_double('SolidusSixSaferpay::Gateway'))
  end

  describe 'liability_shift check' do
    before do
      # ensure validation does not affect outcome
      allow(Spree::SolidusSixSaferpay::PaymentValidator).to receive(:call).with(payment)
      allow(payment).to receive(:create_solidus_payment!)

      allow(subject.gateway).to receive(:void).with(payment.transaction_id)
    end

    context 'when liability shift is required' do
      context 'when liability shift is not granted' do
        let(:payment) { create(:six_saferpay_payment, :authorized, :without_liability_shift) }

        it 'cancels the payment' do
          subject.call

          expect(subject.gateway).to have_received(:void)
        end

        it 'indicates failure' do
          subject.call

          expect(subject).not_to be_success
        end
      end

      context 'when liability shift is granted' do
        it "doesn't cancel the payment" do
          subject.call

          expect(subject.gateway).not_to have_received(:void)
        end

        it 'passes the liability shift check' do
          subject.call

          expect(subject).to be_success
        end
      end
    end

    context 'when liability shift is not required' do
      let(:payment_method) { create(:saferpay_payment_method, :no_require_liability_shift) }

      context 'when liability shift is not granted' do
        let(:payment) {
          create(:six_saferpay_payment, :authorized, :without_liability_shift, payment_method: payment_method)
        }

        it "doesn't cancel the payment" do
          subject.call

          expect(subject.gateway).not_to have_received(:void)
        end

        it 'passes the liability shift check' do
          subject.call

          expect(subject).to be_success
        end
      end

      context 'when liability shift is granted' do
        let(:payment) { create(:six_saferpay_payment, :authorized, payment_method: payment_method) }

        it "doesn't cancel the payment" do
          subject.call

          expect(subject.gateway).not_to have_received(:void)
        end

        it 'passes the liability shift check' do
          subject.call

          expect(subject).to be_success
        end
      end
    end
  end

  describe 'payment validation' do
    it 'validates the payment' do
      allow(Spree::SolidusSixSaferpay::PaymentValidator).to receive(:call).with(payment)
      subject.call
      expect(Spree::SolidusSixSaferpay::PaymentValidator).to have_received(:call)
    end

    context 'when the payment is invalid' do
      it 'cancels the payment' do
        allow(subject.gateway).to receive(:void).with(payment.transaction_id)
        subject.call

        expect(subject.gateway).to have_received(:void).with(payment.transaction_id)
      end

      it 'indicates failure' do
        allow(subject.gateway).to receive(:void).with(payment.transaction_id)

        subject.call

        expect(subject).not_to be_success
      end
    end

    context 'when the payment is valid' do
      before do
        allow(Spree::SolidusSixSaferpay::PaymentValidator).to receive(:call).with(payment).and_return(true)
      end

      it "doesn't cancel the payment" do
        allow(subject.gateway).to receive(:void)
        subject.call
        expect(subject.gateway).not_to have_received(:void)
      end

      it 'indicates success' do
        subject.call

        expect(subject).to be_success
      end
    end
  end

  context 'when the payment has passed all validations' do
    before do
      # assume liability shift is not necessary
      allow(payment.payment_method).to receive(:preferred_require_liability_shift).and_return(false)
      # assume payment is valid
      allow(Spree::SolidusSixSaferpay::PaymentValidator).to receive(:call).with(payment).and_return(true)
    end

    context 'when previous solidus payments exist for this order' do
      let(:order) { payment.order }
      let!(:previous_payment_checkout) { create(:payment_using_saferpay, order: order) }

      before do
        # This is bad practice because we mock which payments are invalidated here.
        # The reason is that you can't stub methods on AR objects that
        # are loaded from the DB and because #solidus_payments_to_cancel
        # is just AR scopes, I prefer this test over using stuff like
        # #expect_any_instance_of
        allow(subject).to receive(:solidus_payments_to_cancel).and_return([previous_payment_checkout]) # rubocop:disable RSpec/SubjectStub
      end

      it 'cancels old solidus payments' do
        allow(previous_payment_checkout).to receive(:cancel!)
        subject.call

        expect(previous_payment_checkout).to have_received(:cancel!)
      end
    end

    it 'creates a new solidus payment' do
      allow(payment).to receive(:create_solidus_payment!)
      subject.call
      expect(payment).to have_received(:create_solidus_payment!)
    end

    it 'indicates success' do
      allow(payment).to receive(:create_solidus_payment!)

      subject.call

      expect(subject).to be_success
    end
  end
end
