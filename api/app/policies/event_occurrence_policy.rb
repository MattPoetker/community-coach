# frozen_string_literal: true

class EventOccurrencePolicy < ApplicationPolicy
  def rsvp? = member?

  class Scope < ApplicationPolicy::Scope
    def resolve = membership&.active? ? scope.all : scope.none
  end
end
