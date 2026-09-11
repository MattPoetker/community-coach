# frozen_string_literal: true

module Api
  module V1
    class CommunitiesController < BaseController
      # The landing page and the brand tokens must both render for a signed-out visitor;
      # neither exposes anything a member would not show a prospect.
      skip_before_action :authenticate!, only: %i[show branding]
      skip_before_action :require_membership!, only: %i[show branding]
      skip_after_action :verify_authorized

      # Declared as a before_action, not called inside the action: a rendered error does
      # not halt a method, so an inline check would 403 and still run the update.
      before_action :require_staff!, only: %i[update]

      # The public landing payload. A secret community is invisible to non-members; a
      # private one shows its sales page but not its content.
      def show
        community = Current.community
        if community.privacy == "secret" && !current_membership
          return render_error(:not_found, "not_found", "That does not exist.")
        end

        render json: {
          community: CommunitySerializer.new(community, params: { membership: current_membership }).as_json,
          plans: PlanSerializer.new(community.plans.visible).as_json,
          stats: stats(community)
        }
      end

      def update
        community = Current.community
        community.update!(community_params)
        AuditLog.record!(action: "community.update", actor: current_user, subject: community)
        render json: { community: CommunitySerializer.new(community, params: { membership: current_membership }).as_json }
      end

      # Compiled brand tokens. Emitted as a <style> block by the frontend, after themes.css,
      # so an owner's overrides win without any !important in the codebase.
      def branding
        skip_authorization
        result = Branding::TokenCompiler.call(
          Current.community.branding, preset_defaults: Branding::Presets.fetch(preset_key)
        )
        render json: { css: result.css, warnings: result.warnings }
      end

      private

      def preset_key = Current.community.branding["preset"].presence || Branding::Presets::DEFAULT

      def community_params
        params.require(:community).permit(:name, :tagline, :description, :privacy, :timezone,
                                          branding: {}, settings: {})
      end

      def stats(community)
        { members: community.memberships.active.count,
          online: community.memberships.where(last_seen_at: 5.minutes.ago..).count,
          admins: community.memberships.staff.count }
      end
    end
  end
end
