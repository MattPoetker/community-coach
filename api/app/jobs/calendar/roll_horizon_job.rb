# frozen_string_literal: true

module Calendar
  # Keeps the materialised horizon rolling forward. Without this a weekly call would
  # quietly stop appearing twelve months after it was created — the kind of bug that shows
  # up as "the calendar is empty" a year after anyone touched the code.
  class RollHorizonJob < ApplicationJob
    queue_as :default

    def perform
      Community.find_each do |community|
        ActsAsTenant.with_tenant(community) do
          Event.live.where.not(rrule: nil).find_each { MaterialiseOccurrences.call(_1) }
        end
      end
    end
  end
end
