# frozen_string_literal: true

module Spree
  class PaymentMethod
    class MercadoPago < Spree::PaymentMethod
      preference :public_key, :string, default: Rails.application.credentials.dig(:mercado_pago, :public_key)
      preference :access_token, :string, default: Rails.application.credentials.dig(:mercado_pago, :access_token)

      def source_required?
        false
      end

      # Indicates whether its possible to void the payment.
      def can_void?(payment)
        payment.state != 'void'
      end

      def actions
        %w[void]
      end

      def void(*_args)
        ActiveMerchant::Billing::Response.new(true, '', {}, {})
      end
    end
  end
end
