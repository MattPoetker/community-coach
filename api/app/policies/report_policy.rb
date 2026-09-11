# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def index? = staff?
  def create? = member?   # anyone can flag something
  def update? = staff?
  def destroy? = staff?

  class Scope < ApplicationPolicy::Scope
    # Staff see the whole queue; nobody else has any business reading it.
    def resolve = membership&.staff? ? scope.all : scope.none
  end
end
