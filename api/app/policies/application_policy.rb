# frozen_string_literal: true

# Pundit answers questions about *role*: may this person perform this action. Whether they
# can see a thing at all is entitlement, and lives in Access::Resolver. Keeping them apart
# is deliberate — conflating them is how paywalls leak.
class ApplicationPolicy
  attr_reader :membership, :record

  def initialize(membership, record)
    @membership = membership
    @record = record
  end

  def index? = member?
  def show? = member?
  def create? = member?
  def update? = owner_of_record? || staff?
  def destroy? = owner_of_record? || staff?

  private

  def member? = membership&.active?
  def staff? = membership&.staff?
  def admin? = membership&.admin?

  def owner_of_record?
    member? && record.respond_to?(:user_id) && record.user_id == membership.user_id
  end

  class Scope
    attr_reader :membership, :scope

    def initialize(membership, scope)
      @membership = membership
      @scope = scope
    end

    def resolve = scope.all
  end
end
