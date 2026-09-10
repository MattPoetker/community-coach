# frozen_string_literal: true

module Api
  module V1
    class PostsController < BaseController
      def index
        scope = policy_scope(Post).includes(:user, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.pinned_first

        page = paginate(scope, cursor_column: :last_activity_at)
        render json: {
          posts: PostSerializer.new(page[:records], params: serializer_params(page[:records])).as_json,
          next_cursor: page[:next_cursor]
        }
      end

      def show
        post = policy_scope(Post).find(params[:id])
        authorize post
        authorize_access!(post.category)

        render json: { post: PostSerializer.new(post, params: serializer_params([post])).as_json }
      end

      def create
        post = Post.new(post_params.merge(user: current_user, community: Current.community))
        authorize post
        RichText::Document.new(post.body).validate!

        ActiveRecord::Base.transaction do
          post.save!
          ThreadSubscription.ensure!(subject: post, user: current_user, reason: "author")
          Notifications::FanOut.new_post(post)
        end

        render json: { post: PostSerializer.new(post, params: serializer_params([post])).as_json },
               status: :created
      end

      def update
        post = policy_scope(Post).find(params[:id])
        authorize post
        RichText::Document.new(post_params[:body]).validate! if post_params[:body]

        post.update!(post_params.merge(edited_at: Time.current))
        render json: { post: PostSerializer.new(post, params: serializer_params([post])).as_json }
      end

      def destroy
        post = policy_scope(Post).find(params[:id])
        authorize post
        post.discard!
        AuditLog.record!(action: "post.delete", actor: current_user, subject: post)
        head :no_content
      end

      def pin
        post = policy_scope(Post).find(params[:id])
        authorize post, :pin?
        post.update!(pinned_at: post.pinned? ? nil : Time.current)
        render json: { post: PostSerializer.new(post, params: serializer_params([post])).as_json }
      end

      def lock
        post = policy_scope(Post).find(params[:id])
        authorize post, :lock?
        post.update!(locked_at: post.locked? ? nil : Time.current)
        render json: { post: PostSerializer.new(post, params: serializer_params([post])).as_json }
      end

      private

      def post_params
        params.require(:post).permit(:title, :category_id, :kind, body: {})
      end

      # One query for the viewer's reactions across the whole page rather than one per row.
      def serializer_params(posts)
        { reacted_post_ids: Reaction.where(user: current_user, reactable: posts).pluck(:reactable_id).to_set,
          membership: current_membership }
      end
    end
  end
end
