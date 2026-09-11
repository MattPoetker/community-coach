# frozen_string_literal: true

class ReportSerializer < ApplicationSerializer
  attributes :id, :reason, :detail, :state, :created_at, :resolved_at

  attribute(:subject_type) { _1.subject_type }
  attribute(:subject_id) { _1.subject_id }
  attribute(:subject_title) do |report|
    subject = report.subject
    subject.respond_to?(:title) ? subject.title : subject&.body_text&.truncate(120)
  end

  one :reporter, resource: UserSerializer
end
