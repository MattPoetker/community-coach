# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Membership management", type: :request do
  let(:community) { create(:community) }
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let!(:owner_membership) { create(:membership, user: owner, community: community, role: "owner") }
  let!(:member_membership) { create(:membership, user: member, community: community) }

  before { ActsAsTenant.current_tenant = community }

  describe "invitations" do
    it "issues one invitation per new address" do
      sign_in(owner, community)
      post "/api/v1/invitations",
           params: { email_addresses: %w[one@example.com two@example.com] }.to_json,
           headers: headers_for(community)

      expect(response).to have_http_status(:created)
      expect(json["invitations"].size).to eq(2)
    end

    it "skips people who are already members instead of sending a dead link" do
      sign_in(owner, community)
      post "/api/v1/invitations",
           params: { email_addresses: [member.email_address, "new@example.com"] }.to_json,
           headers: headers_for(community)

      expect(json["invitations"].size).to eq(1)
      expect(json["skipped"]).to eq(1)
    end

    it "refuses ordinary members" do
      sign_in(member, community)
      post "/api/v1/invitations",
           params: { email_addresses: %w[x@example.com] }.to_json,
           headers: headers_for(community)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "join requests" do
    let(:outsider) { create(:user) }

    it "creates a request for someone who is not yet a member" do
      sign_in(outsider, community)
      post "/api/v1/join_requests",
           params: { answers: { why: "I price by the day and want to stop" } }.to_json,
           headers: headers_for(community)

      expect(response).to have_http_status(:created)
      expect(JoinRequest.count).to eq(1)
    end

    it "refuses someone who already belongs" do
      sign_in(member, community)
      post "/api/v1/join_requests", params: {}.to_json, headers: headers_for(community)

      expect(response).to have_http_status(:conflict)
    end

    it "creates a membership on approval" do
      request = JoinRequest.create!(community: community, user: outsider, state: "pending")
      sign_in(owner, community)

      post "/api/v1/join_requests/#{request.id}/review",
           params: { decision: "approve" }.to_json, headers: headers_for(community)

      expect(response).to have_http_status(:ok)
      expect(Membership.exists?(user: outsider, community: community)).to be(true)
    end

    it "creates no membership on rejection" do
      request = JoinRequest.create!(community: community, user: outsider, state: "pending")
      sign_in(owner, community)

      post "/api/v1/join_requests/#{request.id}/review",
           params: { decision: "reject" }.to_json, headers: headers_for(community)

      expect(Membership.exists?(user: outsider, community: community)).to be(false)
      expect(request.reload.state).to eq("rejected")
    end
  end

  describe "suspension" do
    it "ends the suspended member's sessions, so a ban takes effect immediately" do
      sign_in(member, community)
      expect(member.sessions.count).to eq(1)

      sign_in(owner, community)
      post "/api/v1/members/#{member_membership.id}/suspend",
           params: { reason: "Repeated spam" }.to_json, headers: headers_for(community)

      expect(response).to have_http_status(:no_content)
      expect(member_membership.reload.status).to eq("suspended")
      expect(member.sessions.count).to eq(0)
    end
  end
end
