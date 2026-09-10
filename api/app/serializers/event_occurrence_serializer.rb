# frozen_string_literal: true

class EventOccurrenceSerializer < ApplicationSerializer
  attributes :id, :starts_at, :ends_at

  attribute(:title) { _1.event.title }
  attribute(:description) { _1.event.description }
  attribute(:timezone) { _1.event.timezone }
  attribute(:location_kind) { _1.event.location_kind }
  attribute(:cancelled) { _1.cancelled? }
  attribute(:recurring) { _1.event.recurring? }
  attribute(:going_count) { _1.event_rsvps.count { |r| r.state == "going" } }

  attribute(:host) { UserSerializer.new(_1.event.host).to_h }

  # The joining link is serialised only for members who have said they are coming, so a
  # calendar view cannot hand the Zoom URL to people who never RSVP'd.
  attribute :location_url do |occurrence|
    occurrence.event.location_url if params[:rsvps]&.dig(occurrence.id)&.state == "going"
  end

  attribute :my_rsvp do |occurrence|
    params[:rsvps]&.dig(occurrence.id)&.state
  end
end
