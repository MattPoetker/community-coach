# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PlansController < BaseController
        def index
          skip_authorization
          render json: { plans: PlanSerializer.new(Plan.order(:position, :amount_cents)).as_json }
        end

        def create
          plan = Plan.new(plan_params.merge(community: Current.community,
                                            currency: Current.community.currency))
          authorize plan
          plan.slug = plan.slug.presence || plan.name.to_s.parameterize
          plan.save!
          render json: { plan: PlanSerializer.new(plan).as_json }, status: :created
        end

        def update
          plan = Plan.find(params[:id])
          authorize plan
          plan.update!(plan_params)
          render json: { plan: PlanSerializer.new(plan).as_json }
        end

        # Plans are hidden rather than deleted once anyone has subscribed: destroying one
        # would orphan live subscriptions and the invoice history attached to them.
        def destroy
          plan = Plan.find(params[:id])
          authorize plan
          if plan.subscriptions.exists?
            plan.update!(visible: false)
            render json: { plan: PlanSerializer.new(plan).as_json, hidden_instead: true }
          else
            plan.destroy!
            head :no_content
          end
        end

        private

        def plan_params
          params.require(:plan).permit(:name, :slug, :description, :interval, :amount_cents,
                                       :trial_days, :provider_price_id, :visible, :position,
                                       features: [])
        end
      end
    end
  end
end
