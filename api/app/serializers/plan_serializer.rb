# frozen_string_literal: true

class PlanSerializer < ApplicationSerializer
  attributes :id, :name, :slug, :description, :interval, :amount_cents,
             :currency, :trial_days, :features, :position

  attribute(:price) { _1.price }
  attribute(:free) { _1.free? }
end
