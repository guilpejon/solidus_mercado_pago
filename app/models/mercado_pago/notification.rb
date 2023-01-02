# frozen_string_literal: true

module MercadoPago
  class Notification < ApplicationRecord
    self.table_name = 'mercado_pago_notifications'

    validates :topic, presence: true, inclusion: { in: %w[payment preapproval authorized_payment merchant_order] }
    validates :operation_id, presence: true
  end
end
