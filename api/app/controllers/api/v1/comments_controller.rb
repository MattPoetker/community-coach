# frozen_string_literal: true

module Api
  module V1
    class CommentsController < BaseController
      def index
        post = policy_scope(Post).find(params[:post_id])
        authorize_access!(post.category)

        comments = post.comments.threaded.includes(:user)
        skip_policy_scope
        render json: { comments: CommentSerializer.new(comments).as_json }
      end

      def create
        post = policy_scope(Post).find(params[:post_id])
        comment = post.comments.new(comment_params.merge(user: current_user,
                                                         community: Current.community))
        authorize comment
        RichText::Document.new(comment.body).validate!

        ActiveRecord::Base.transaction do
          comment.save!
          ThreadSubscription.ensure!(subject: post, user: current_user, reason: "participant")
          Notifications::FanOut.new_comment(comment)
        end

        render json: { comment: CommentSerializer.new(comment).as_json }, status: :created
      end

      def update
        comment = Comment.find(params[:id])
        authorize comment
        RichText::Document.new(comment_params[:body]).validate!
        comment.update!(body: comment_params[:body], edited_at: Time.current)
        render json: { comment: CommentSerializer.new(comment).as_json }
      end

      def destroy
        comment = Comment.find(params[:id])
        authorize comment
        comment.discard!
        head :no_content
      end

      private

      def comment_params = params.require(:comment).permit(:parent_id, body: {})
    end
  end
end
