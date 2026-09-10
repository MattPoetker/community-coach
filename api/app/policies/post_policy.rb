# frozen_string_literal: true

class PostPolicy < ApplicationPolicy
  def create?
    return false unless member?
    return staff? if record.category&.post_permission == "admins"

    Access::Resolver.granted?(membership, record.category)
  end

  def update? = (owner_of_record? && !record.locked?) || staff?
  def destroy? = owner_of_record? || staff?
  def pin? = staff?
  def lock? = staff?

  class Scope < ApplicationPolicy::Scope
    # Categories a member cannot enter must not leak their posts through the feed. Gates
    # are resolved once per request rather than per row.
    def resolve
      return scope.none unless membership&.active?
      return scope.kept if membership.staff?

      permitted = Category.where(community_id: membership.community_id).select do |category|
        Access::Resolver.granted?(membership, category)
      end
      scope.kept.where(category_id: permitted.map(&:id))
    end
  end
end
