# frozen_string_literal: true

module Api
  module V1
    module Admin
      class EventsController < BaseController
        def create
          event = Event.new(event_params.merge(community: Current.community,
                                               host: host_from_params))
          authorize event
          event.save!
          render json: { event: serialize(event) }, status: :created
        end

        def update
          event = Event.find(params[:id])
          authorize event
          event.update!(event_params)
          # The after_commit hook re-materialises occurrences; rows an admin edited
          # individually are preserved by the overridden flag.
          render json: { event: serialize(event) }
        end

        def destroy
          event = Event.find(params[:id])
          authorize event
          event.update!(cancelled_at: Time.current)
          AuditLog.record!(action: "event.cancel", actor: current_user, subject: event)
          head :no_content
        end

        private

        def event_params
          params.require(:event).permit(:title, :description, :starts_at, :duration_minutes,
                                        :timezone, :rrule, :recurrence_end_at,
                                        :location_kind, :location_url, access_rule: {})
        end

        def host_from_params
          return current_user if params[:event][:host_id].blank?

          Membership.staff.find_by!(user_id: params[:event][:host_id]).user
        end

        def serialize(event)
          { id: event.id, title: event.title, starts_at: event.starts_at,
            timezone: event.timezone, rrule: event.rrule,
            occurrences: event.event_occurrences.upcoming.limit(5).pluck(:starts_at) }
        end
      end
    end
  end
end
