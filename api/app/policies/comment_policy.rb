# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false unless member?
    return false if record.post&.locked? && !staff?

    Access::Resolver.granted?(membership, record.post&.category)
  end

  def update? = owner_of_record? || staff?
  def destroy? = owner_of_record? || staff?
end
