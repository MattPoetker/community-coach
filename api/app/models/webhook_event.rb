# frozen_string_literal: true

# The idempotency spine for billing. Providers retry, deliver out of order and occasionally
# deliver twice; the unique index on (provider, provider_event_id) is what makes every
# handler safe to replay.
class WebhookEvent < ApplicationRecord
  validates :provider, :provider_event_id, :event_type, presence: true

  scope :unprocessed, -> { where(processed_at: nil) }

  def processed? = processed_at.present?

  def self.record!(provider:, event_id:, type:, payload:)
    create!(provider: provider, provider_event_id: event_id, event_type: type, payload: payload)
  rescue ActiveRecord::RecordNotUnique
    find_by!(provider: provider, provider_event_id: event_id)
  end

  def process!
    return :already_processed if processed?

    increment!(:attempts)
    yield
    update!(processed_at: Time.current, error_message: nil)
    :processed
  rescue StandardError => e
    update!(error_message: "#{e.class}: #{e.message}")
    raise
  end
end
