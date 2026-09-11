# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        def destroy
          category = Category.find(params[:id])
          authorize category
          if category.posts.kept.exists?
            return render_error(:conflict, "category_not_empty",
                                "Move or delete the posts in this category first.")
          end

          category.destroy!
          head :no_content
        end

        def reorder
          skip_authorization
          ActiveRecord::Base.transaction do
            params.require(:category_ids).map(&:to_i).each_with_index do |id, index|
              Category.where(id: id).update_all(position: index)
            end
          end
          head :no_content
        end
      end
    end
  end
end
