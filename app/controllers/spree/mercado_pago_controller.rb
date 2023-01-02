require 'mercadopago'

module Spree
  class MercadoPagoController < StoreController
    protect_from_forgery

    def checkout
      current_order.state_name == :payment || raise(ActiveRecord::RecordNotFound)
      payment_method = PaymentMethod::MercadoPago.find(params[:payment_method_id])
      payment = current_order.payments
                             .create!(amount: current_order.total, payment_method: payment_method)
      payment.started_processing!

      preferences = ::MercadoPago::OrderPreferencesBuilder
                    .new(current_order, payment, callback_urls)
                    .preferences_hash

      response = mercado_pago_sdk.preference.create(preferences)

      redirect_to response[:response]["init_point"], allow_other_host: true
    end

    # Success/pending callbacks are currently aliases, this may change
    # if required.
    def success
      payment = Spree::Payment.find_by(number: params[:external_reference])
      payment.order.next!
      flash.notice = I18n.t(:order_processed_successfully, scope: :spree)
      flash['order_completed'] = true
      redirect_to main_app.order_path(payment.order)
    end

    def failure
      payment = Spree::Payment.find_by(number: params[:external_reference])
      payment.failure!
      flash.notice = I18n.t(:payment_processing_failed, scope: :spree)
      flash['order_completed'] = true
      redirect_to main_app.checkout_state_path(state: :payment)
    end

    def ipn
      notification = MercadoPago::Notification.new(operation_id: params[:id], topic: params[:topic])

      if notification.save
        MercadoPago::HandleReceivedNotification.new(notification).process!
        status = :ok
      else
        status = :bad_request
      end

      render json: :empty, status: status
    end

    private

    def callback_urls
      @callback_urls ||= {
        success: mercado_pago_success_url,
        pending: mercado_pago_success_url,
        failure: mercado_pago_failure_url
      }
    end

    def mercado_pago_sdk
      access_token = Rails.application.credentials.dig(:mercado_pago, :access_token)
      @mercado_pago_sdk ||= Mercadopago::SDK.new(access_token)
    end
  end
end
