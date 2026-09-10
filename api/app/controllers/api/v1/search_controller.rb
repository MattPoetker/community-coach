# frozen_string_literal: true

module Api
  module V1
    class SearchController < BaseController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      def index
        results = Search::Query.call(params[:q], community: Current.community)

        # Search must not become a way to read categories you cannot enter.
        posts = results[:posts].select do |post|
          Access::Resolver.granted?(current_membership, post.category)
        end

        render json: {
          posts: PostSerializer.new(posts, params: { membership: current_membership }).as_json,
          lessons: LessonSerializer.new(results[:lessons], params: { membership: current_membership }).as_json
        }
      end
    end
  end
end
