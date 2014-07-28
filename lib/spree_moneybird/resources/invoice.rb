module SpreeMoneybird
  class Invoice < BaseResource
    def self.send_invoice(order)
      invoice = self.from_order order
      invoie_send_data = { invoice: { email: order.email,
                                      send_method: 'hand' } }
      invoice.put :send_invoice, nil, invoie_send_data.to_json # There must be a nicer way to do this
      invoice
    end

    def self.create_invoice_from_order(order)
      invoice = from_order(order)
      invoice.save # Move this save to self.from_order

      order.moneybird_id = invoice.id
      order.moneybird_invoice_url = invoice.url
      order.save!

      invoice
    end

    def self.from_order(order)
      return self.find(order.moneybird_id) unless order.moneybird_id.nil?

      tax_rate = SpreeMoneybird::TaxRate.all.first # TODO: Fix hardcode tax setting

      details_attributes = order.line_items.map do |line_item|
        { description: line_item.variant.name,
          amount: line_item.quantity,
          created_at: line_item.created_at,
          tax_rate_id: tax_rate.id,
          price: line_item.price }
      end

      # This will add a shipment rule to the invoice
      details_attributes << { description: "Verzending",
                              price: order.ship_total,
                              tax_rate_id: tax_rate.id }

      attrs = { invoice: { contact_id: (order.user.moneybird_id if order.user),
                           contact_name_search: order.billing_address.company,
                           company_name: order.billing_address.company,
                           firstname: order.billing_address.firstname,
                           lastname: order.billing_address.lastname,
                           address1: order.billing_address.address1,
                           address2: order.billing_address.address2,
                           zipcode: order.billing_address.zipcode,
                           city: order.billing_address.city,
                           country: order.billing_address.country.iso_name,
                           details_attributes: details_attributes } }

      self.new attrs
    end
  end
end
