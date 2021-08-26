# frozen_string_literal: true

module SolidusSixSaferpay
  # This class is used to determine the type of an order item according to the
  # SixSaferpay API documentation under
  # [PaymentPage|Transaction] Initialize > Request Arguments
  #   > Order
  #     > Items
  #       > Type
  #
  # This very simple default implementation can be overridden by configuring SolidusSixSaferpay::Config.line_item_type_deductor_class
  class LineItemTypeDeductor
    attr_reader :line_item

    def initialize(line_item)
      @line_item = line_item
    end

    def type
      'PHYSICAL'
    end
  end
end