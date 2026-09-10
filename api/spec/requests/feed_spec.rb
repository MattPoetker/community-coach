# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Community feed", type: :request do
  let(:community) { create(:community) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, community: community) }
  let(:category) { create(:category, community: community) }

  before { ActsAsTenant.current_tenant = community }

  it "lists posts with pinned ones first" do
    create(:post, community: community, category: category, user: user,
                  title: "Ordinary", last_activity_at: 1.minute.ago)
    create(:post, community: community, category: category, user: user,
                  title: "Pinned", pinned_at: Time.current, last_activity_at: 1.hour.ago)

    sign_in(user, community)
    get "/api/v1/posts", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(json["posts"].map { _1["title"] }).to eq(%w[Pinned Ordinary])
  end

  it "creates a post and subscribes the author to its thread" do
    sign_in(user, community)
    post "/api/v1/posts",
         params: { post: { title: "A question about pricing", category_id: category.id,
                           body: RichText::Document.from_plain_text("How do you scope discovery?") } }.to_json,
         headers: headers_for(community)

    expect(response).to have_http_status(:created)
    created = Post.find(json.dig("post", "id"))
    expect(ThreadSubscription.exists?(subject: created, user: user, reason: "author")).to be(true)
  end

  it "refuses a rich text document containing a javascript: link" do
    sign_in(user, community)
    body = { "type" => "doc", "content" => [
      { "type" => "text", "text" => "click",
        "marks" => [{ "type" => "link", "attrs" => { "href" => "javascript:alert(1)" } }] }
    ] }

    post "/api/v1/posts",
         params: { post: { title: "Bad link", category_id: category.id, body: body } }.to_json,
         headers: headers_for(community)

    expect(response).to have_http_status(:bad_request)
  end

  it "does not leak posts from another community" do
    other = create(:community)
    ActsAsTenant.with_tenant(other) do
      create(:post, community: other, category: create(:category, community: other),
                    user: create(:user), title: "Someone else's post")
    end

    sign_in(user, community)
    get "/api/v1/posts", headers: headers_for(community)

    expect(json["posts"].map { _1["title"] }).not_to include("Someone else's post")
  end

  it "hides posts in a category the member's plan does not include" do
    gated = create(:category, community: community,
                              access_rule: { "plan_in" => %w[inner-circle] })
    create(:post, community: community, category: gated, user: user, title: "Paid only")
    create(:post, community: community, category: category, user: user, title: "Open")

    sign_in(user, community)
    get "/api/v1/posts", headers: headers_for(community)

    titles = json["posts"].map { _1["title"] }
    expect(titles).to include("Open")
    expect(titles).not_to include("Paid only")
  end
end
