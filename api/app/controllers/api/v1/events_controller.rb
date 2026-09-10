# frozen_string_literal: true

module Api
  module V1
    class EventsController < BaseController
      def index
        from = params[:from].present? ? Time.zone.parse(params[:from]) : Time.current
        to = params[:to].present? ? Time.zone.parse(params[:to]) : 60.days.from_now

        occurrences = policy_scope(EventOccurrence)
                      .in_range(from, to)
                      .where(cancelled_at: nil)
                      .includes(event: :host)
                      .includes(:event_rsvps)

        render json: {
          events: EventOccurrenceSerializer.new(occurrences, params: {
            rsvps: rsvp_map(occurrences)
          }).as_json
        }
      end

      def rsvp
        occurrence = EventOccurrence.find(params[:id])
        skip_authorization
        authorize_access!(occurrence.event)

        entry = EventRsvp.find_or_initialize_by(event_occurrence: occurrence, user: current_user)
        entry.community = Current.community
        entry.state = params.fetch(:state, "going")
        entry.save!

        render json: { state: entry.state, going_count: occurrence.going_count,
                       location_url: entry.state == "going" ? occurrence.event.location_url : nil }
      end

      private

      def rsvp_map(occurrences)
        EventRsvp.where(user: current_user, event_occurrence: occurrences)
                 .index_by(&:event_occurrence_id)
      end
    end
  end
end
