RSpec.shared_examples 'process_authorized_payment' do
  before do
    allow(subject).to receive(:gateway).and_return(double('gateway'))
  end

  context 'liability_shift check' do

    before do
      # ensure other methods don't modify outcome
      allow(subject).to receive(:validate_payment!)
      allow(subject).to receive(:cancel_old_solidus_payments)
      allow(payment).to receive(:create_solidus_payment!)
    end

    context 'when liability shift is required' do
      context 'and liability shift is not granted' do

        let(:payment) { create(:six_saferpay_payment, :authorized, :without_liability_shift) }

        it 'cancels the payment' do
          expect(payment.payment_method.preferred_require_liability_shift).to be true
          expect(payment.liability.liability_shift).to be false

          expect(subject.gateway).to receive(:void).with(payment.transaction_id)

          subject.call
        end

        it 'indicates failure' do
          expect(payment.payment_method.preferred_require_liability_shift).to be true
          expect(payment.liability.liability_shift).to be false

          expect(subject.gateway).to receive(:void).with(payment.transaction_id)

          subject.call

          expect(subject).not_to be_success
        end

      end

      context 'and liability shift is granted' do
        it "doesn't cancel the payment" do
          expect(payment.payment_method.preferred_require_liability_shift).to be true
          expect(payment.liability.liability_shift).to be true

          expect(subject.gateway).not_to receive(:void)

          subject.call
        end

        it 'passes the liability shift check' do
          expect(payment.payment_method.preferred_require_liability_shift).to be true
          expect(payment.liability.liability_shift).to be true

          subject.call

          expect(subject).to be_success
        end
      end
    end

    context 'when liability shift is not required' do
      let(:payment_method) { create(:saferpay_payment_method, :no_require_liability_shift) }

      context 'and liability shift is not granted' do
        let(:payment) { create(:six_saferpay_payment, :authorized, :without_liability_shift, payment_method: payment_method) }

        it "doesn't cancel the payment" do
          expect(payment.payment_method.preferred_require_liability_shift).to be false
          expect(payment.liability.liability_shift).to be false

          expect(subject.gateway).not_to receive(:void)

          subject.call
        end

        it 'passes the liability shift check' do
          expect(payment.payment_method.preferred_require_liability_shift).to be false
          expect(payment.liability.liability_shift).to be false
          subject.call

          expect(subject).to be_success
        end
      end

      context 'and liability shift is granted' do
        let(:payment) { create(:six_saferpay_payment, :authorized, payment_method: payment_method) }
        it "doesn't cancel the payment" do
          expect(payment.payment_method.preferred_require_liability_shift).to be false
          expect(payment.liability.liability_shift).to be true

          expect(subject.gateway).not_to receive(:void)

          subject.call
        end

        it 'passes the liability shift check' do
          expect(payment.payment_method.preferred_require_liability_shift).to be false
          expect(payment.liability.liability_shift).to be true
          subject.call

          expect(subject).to be_success
        end
      end
    end
  end

  context 'payment validation' do
    before do
      allow(subject).to receive(:gateway).and_return(double('gateway'))


      # ensure other methods don't modify outcome
      allow(subject).to receive(:check_liability_shift_requirements!)
      allow(subject).to receive(:cancel_old_solidus_payments)
      allow(payment).to receive(:create_solidus_payment!)
    end

    it 'validates the payment' do
      expect(Spree::SolidusSixSaferpay::PaymentValidator).to receive(:call).with(payment)
      subject.call
    end

    context 'when the payment is invalid' do
      it 'cancels the payment' do
        expect(subject.gateway).to receive(:void).with(payment.transaction_id)

        subject.call
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
        expect(subject.gateway).not_to receive(:void)

        subject.call
      end

      it 'indicates success' do
        subject.call

        expect(subject).to be_success
      end
    end
  end

  context 'when the payment has passed all validations' do
    before do
      allow(subject).to receive(:check_liability_shift_requirements!).and_return(true)
      allow(subject).to receive(:validate_payment!).and_return(true)
    end

    context 'when previous solidus payments exist for this order' do
      let(:order) { payment.order }
      let!(:previous_payment_invalid) { create(:payment_using_saferpay, order: order) }
      let!(:previous_payment_checkout) { create(:payment_using_saferpay, order: order) }

      before do
        # This is bad practice because we mock which payments are invalidated here.
        # The reason is that you can't stub methods on AR objects that
        # are loaded from the DB and because #solidus_payments_to_cancel
        # is just AR scopes, I prefer this test over using stuff like
        # #expect_any_instance_of
        allow(subject).to receive(:solidus_payments_to_cancel).and_return([previous_payment_checkout])
      end

      it 'cancels old solidus payments' do
        expect(previous_payment_invalid).not_to receive(:cancel!)
        expect(previous_payment_checkout).to receive(:cancel!)

        subject.call
      end
    end

    it 'creates a new solidus payment' do
      expect(payment).to receive(:create_solidus_payment!)

      subject.call
    end

    it 'indicates success' do
      allow(payment).to receive(:create_solidus_payment!)

      subject.call

      expect(subject).to be_success
    end
  end
end
