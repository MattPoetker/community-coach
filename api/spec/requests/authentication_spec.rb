# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:community) { create(:community) }
  let!(:user) { create(:user, email_address: "member@example.com") }
  let!(:membership) { create(:membership, user: user, community: community) }

  it "signs in with correct credentials and returns a session cookie" do
    sign_in(user, community)
    expect(json.dig("user", "name")).to eq(user.name)
    expect(response.headers["Set-Cookie"]).to include(ApplicationController::SESSION_COOKIE)
  end

  it "rejects a wrong password" do
    post "/auth/login",
         params: { email_address: user.email_address, password: "nope" }.to_json,
         headers: headers_for(community)
    expect(response).to have_http_status(:unauthorized)
    expect(json.dig("error", "code")).to eq("invalid_credentials")
  end

  it "gives the same answer for an unknown address, so login cannot enumerate accounts" do
    post "/auth/login",
         params: { email_address: "nobody@example.com", password: "nope" }.to_json,
         headers: headers_for(community)
    expect(response).to have_http_status(:unauthorized)
    expect(json.dig("error", "code")).to eq("invalid_credentials")
  end

  it "refuses an unconfirmed account" do
    user.update!(confirmed_at: nil)
    post "/auth/login",
         params: { email_address: user.email_address, password: "correct-horse-battery" }.to_json,
         headers: headers_for(community)
    expect(response).to have_http_status(:forbidden)
  end

  it "requires authentication for member endpoints" do
    get "/api/v1/members/me", headers: headers_for(community)
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a mutation from a foreign origin" do
    sign_in(user, community)
    post "/api/v1/posts",
         params: { post: { title: "x", category_id: 1 } }.to_json,
         headers: headers_for(community, "Origin" => "https://evil.example")
    expect(response).to have_http_status(:forbidden)
    expect(json.dig("error", "code")).to eq("bad_origin")
  end

  it "revokes every session when the password is reset" do
    sign_in(user, community)
    user.update!(password_reset_token: "tok", password_reset_sent_at: Time.current)

    put "/auth/password",
        params: { token: "tok", password: "a-brand-new-passphrase" }.to_json,
        headers: headers_for(community)

    expect(response).to have_http_status(:no_content)
    expect(user.sessions.count).to eq(0)
  end
end
