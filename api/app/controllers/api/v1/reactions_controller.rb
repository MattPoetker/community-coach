# frozen_string_literal: true

module Api
  module V1
    class ReactionsController < BaseController
      REACTABLES = { "Post" => Post, "Comment" => Comment }.freeze

      skip_after_action :verify_authorized

      def toggle
        reactable = find_reactable
        kind = params.fetch(:kind, "like")

        existing = Reaction.find_by(user: current_user, reactable: reactable, kind: kind)
        if existing
          existing.destroy
          render json: { reacted: false, count: reactable.reload.reactions_count }
        else
          Reaction.create!(user: current_user, reactable: reactable, kind: kind,
                           community: Current.community)
          Notifications::FanOut.reaction(reactable, current_user)
          render json: { reacted: true, count: reactable.reload.reactions_count }
        end
      end

      private

      # An allowlist rather than constantize: polymorphic params are attacker-controlled,
      # and `params[:type].constantize` is remote class instantiation.
      def find_reactable
        klass = REACTABLES.fetch(params.require(:reactable_type)) do
          raise ActiveRecord::RecordNotFound
        end
        klass.find(params.require(:reactable_id))
      end
    end
  end
end
