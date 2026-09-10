# frozen_string_literal: true

class CategorySerializer < ApplicationSerializer
  attributes :id, :name, :slug, :description, :position, :post_permission
end
