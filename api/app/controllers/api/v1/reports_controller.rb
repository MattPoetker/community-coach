# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      REPORTABLES = { "Post" => Post, "Comment" => Comment }.freeze

      before_action :require_staff!, only: %i[index resolve]

      def index
        skip_authorization
        reports = policy_scope(Report).open.includes(:reporter, :subject).order(created_at: :desc)
        render json: { reports: ReportSerializer.new(reports).as_json }
      end

      def create
        skip_authorization
        subject = find_subject
        report = Report.create!(
          community: Current.community, reporter: current_user, subject: subject,
          reason: params.require(:reason), detail: params[:detail]
        )
        render json: { report: ReportSerializer.new(report).as_json }, status: :created
      end

      def resolve
        skip_authorization
        report = policy_scope(Report).find(params[:id])
        action = params.require(:action_taken)

        ActiveRecord::Base.transaction do
          apply_action(report, action)
          report.update!(state: action == "dismiss" ? "dismissed" : "actioned",
                         resolved_by: current_user, resolved_at: Time.current)
        end

        AuditLog.record!(action: "report.#{action}", actor: current_user, subject: report)
        render json: { report: ReportSerializer.new(report).as_json }
      end

      private

      # An allowlist rather than constantize — the type comes from the client, and
      # `params[:type].constantize` is remote class instantiation.
      def find_subject
        klass = REPORTABLES.fetch(params.require(:subject_type)) { raise ActiveRecord::RecordNotFound }
        klass.find(params.require(:subject_id))
      end

      def apply_action(report, action)
        case action
        when "remove" then report.subject.discard!
        when "lock" then report.subject.try(:update!, locked_at: Time.current)
        when "dismiss" then nil
        else raise ActionController::BadRequest, "Unknown action"
        end
      end
    end
  end
end
