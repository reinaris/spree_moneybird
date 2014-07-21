require 'spec_helper'

describe SpreeMoneybird::Invoice do
  before do
    Spree::Order.any_instance.stub(:sync_with_moneybird)
  end

  let(:order) do
    order = create :order_ready_to_ship
    order.user.stub(:id) { SecureRandom.uuid } # Prevents 422 (duplicate customer id)
    order
  end

  describe 'create an invoice' do
    context 'without contact syncronisation' do
      subject { order }

      before do
        SpreeMoneybird::Invoice.create_invoice_from_order(order)
      end

      it 'assigns the moneybird id' do
        expect(subject.moneybird_id).not_to be_nil
      end
    end

    context 'with contact syncronisation' do
      let!(:moneybird_contact) do
        SpreeMoneybird::Contact.create_contact_from_order(order)
      end

      let!(:moneybird_invoice) do
        SpreeMoneybird::Invoice.create_invoice_from_order(order)
      end

      # Reload so we get the actual contact_id and not our assigned one
      subject { SpreeMoneybird::Invoice.find(moneybird_invoice.id) }

      it 'invoice has the moneybird contact id' do
        expect(subject.contact_id).to eql(moneybird_contact.id)
      end
    end
  end

  describe 'send an invoice' do
    before do
      SpreeMoneybird::Invoice.create_invoice_from_order(order)
      order.stub(:email) { 'mrwhite@example.com' }
    end

    subject { SpreeMoneybird::Invoice.send_invoice(order) }

    it 'sends the invoice' do
      expect(subject.email).not_to be_nil
    end
  end
end
