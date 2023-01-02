# frozen_string_literal: true

require 'mercadopago'

# Process notification:
# ---------------------
# Fetch collection information
# Find payment by external reference
# If found
#   Update payment status
#   Notify user
# If not found
#   Ignore notification (maybe payment from outside Spree)
module MercadoPago
  class ProcessNotification
    # Equivalent payment states
    # MP state => Spree state
    # =======================
    #
    # approved     => complete
    # pending      => pending
    # in_process   => pending
    # rejected     => failed
    # refunded     => void
    # cancelled    => void
    # in_mediation => pend
    # charged_back => void
    STATES = {
      complete: %w[approved],
      failure: %w[rejected],
      void: %w[refunded cancelled charged_back]
    }.freeze

    attr_reader :notification

    def initialize(notification)
      @notification = notification
    end

    def process!
      access_token = Rails.application.credentials.dig(:mercado_pago, :access_token)
      mercado_pago_sdk = Mercadopago::SDK.new(access_token)
      mercadopago_payment = mercado_pago_sdk.payment.get(notification.operation_id)
      payment = Spree::Payment.find_by(number: mercadopago_payment[:response]['external_reference'])

      return unless mercadopago_payment && payment

      if STATES[:complete].include?(mercadopago_payment['status'])
        payment.complete
      elsif STATES[:failure].include?(mercadopago_payment['status'])
        payment.failure
      elsif STATES[:void].include?(mercadopago_payment['status'])
        payment.void
      end

      # When Spree issue #5246 is fixed we can remove this line
      # payment.order.updater.update
    end
  end
end
