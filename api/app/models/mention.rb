# frozen_string_literal: true

class Mention < ApplicationRecord
  acts_as_tenant :community

  belongs_to :source, polymorphic: true
  belongs_to :mentioned_user, class_name: "User"
end
