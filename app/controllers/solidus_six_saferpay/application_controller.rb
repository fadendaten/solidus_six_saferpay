# frozen_string_literal: true

module SolidusSixSaferpay
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  end
end
