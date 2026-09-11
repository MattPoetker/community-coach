# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moderation", type: :request do
  let(:community) { create(:community) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user) }
  let!(:member_membership) { create(:membership, user: member, community: community) }
  let!(:mod_membership) { create(:membership, user: moderator, community: community, role: "moderator") }
  let(:category) { create(:category, community: community) }
  let!(:post_record) { create(:post, community: community, category: category, user: member) }

  before { ActsAsTenant.current_tenant = community }

  it "lets any member report a post" do
    sign_in(member, community)
    post "/api/v1/reports",
         params: { subject_type: "Post", subject_id: post_record.id, reason: "spam" }.to_json,
         headers: headers_for(community)

    expect(response).to have_http_status(:created)
    expect(Report.count).to eq(1)
  end

  it "refuses an unknown subject type rather than constantizing it" do
    sign_in(member, community)
    post "/api/v1/reports",
         params: { subject_type: "User", subject_id: member.id, reason: "spam" }.to_json,
         headers: headers_for(community)

    expect(response).to have_http_status(:not_found)
  end

  it "hides the queue from ordinary members" do
    sign_in(member, community)
    get "/api/v1/reports", headers: headers_for(community)

    expect(response).to have_http_status(:forbidden)
  end

  it "shows the queue to staff" do
    Report.create!(community: community, reporter: member, subject: post_record, reason: "spam")
    sign_in(moderator, community)
    get "/api/v1/reports", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(json["reports"].size).to eq(1)
  end

  it "removes the reported content when a moderator acts on it" do
    report = Report.create!(community: community, reporter: member, subject: post_record,
                            reason: "spam")
    sign_in(moderator, community)
    post "/api/v1/reports/#{report.id}/resolve",
         params: { action_taken: "remove" }.to_json, headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(post_record.reload).to be_discarded
    expect(report.reload.state).to eq("actioned")
  end

  it "leaves the content alone when a report is dismissed" do
    report = Report.create!(community: community, reporter: member, subject: post_record,
                            reason: "spam")
    sign_in(moderator, community)
    post "/api/v1/reports/#{report.id}/resolve",
         params: { action_taken: "dismiss" }.to_json, headers: headers_for(community)

    expect(post_record.reload).to be_kept
    expect(report.reload.state).to eq("dismissed")
  end
end
