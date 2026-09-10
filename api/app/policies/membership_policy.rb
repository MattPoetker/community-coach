# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  def create? = staff?
  def update? = staff?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = membership&.active? ? scope.all : scope.none
  end
end
