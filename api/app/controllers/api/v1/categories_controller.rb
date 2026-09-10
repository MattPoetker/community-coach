# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      def index
        categories = policy_scope(Category).ordered
        visible = categories.select { Access::Resolver.granted?(current_membership, _1) }
        render json: { categories: CategorySerializer.new(visible).as_json }
      end

      def create
        category = Category.new(category_params.merge(community: Current.community))
        authorize category
        category.save!
        render json: { category: CategorySerializer.new(category).as_json }, status: :created
      end

      def update
        category = policy_scope(Category).find(params[:id])
        authorize category
        category.update!(category_params)
        render json: { category: CategorySerializer.new(category).as_json }
      end

      private

      def category_params
        params.require(:category).permit(:name, :slug, :description, :position,
                                         :post_permission, access_rule: {})
      end
    end
  end
end
