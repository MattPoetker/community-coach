# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin content", type: :request do
  let(:community) { create(:community) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let!(:admin_membership) { create(:membership, user: admin, community: community, role: "admin") }
  let!(:member_membership) { create(:membership, user: member, community: community) }

  before { ActsAsTenant.current_tenant = community }

  it "creates a course and derives a slug from the title" do
    sign_in(admin, community)
    post "/api/v1/admin/courses",
         params: { course: { title: "Pricing Without Flinching" } }.to_json,
         headers: headers_for(community)

    expect(response).to have_http_status(:created)
    expect(Course.last.slug).to eq("pricing-without-flinching")
  end

  it "refuses ordinary members" do
    sign_in(member, community)
    post "/api/v1/admin/courses",
         params: { course: { title: "Nope" } }.to_json, headers: headers_for(community)

    expect(response).to have_http_status(:forbidden)
  end

  it "toggles publication" do
    course = create(:course, community: community, published_at: nil)
    sign_in(admin, community)

    post "/api/v1/admin/courses/#{course.id}/publish", headers: headers_for(community)
    expect(course.reload).to be_published

    post "/api/v1/admin/courses/#{course.id}/publish", headers: headers_for(community)
    expect(course.reload).not_to be_published
  end

  it "reorders lessons from a full ordering rather than a delta" do
    course = create(:course, community: community)
    course_module = create(:course_module, community: community, course: course)
    first = create(:lesson, community: community, course_module: course_module, position: 0)
    second = create(:lesson, community: community, course_module: course_module, position: 1)

    sign_in(admin, community)
    post "/api/v1/admin/lessons/reorder",
         params: { lesson_ids: [second.id, first.id] }.to_json, headers: headers_for(community)

    expect(second.reload.position).to eq(0)
    expect(first.reload.position).to eq(1)
  end

  it "hides a plan with live subscriptions instead of destroying it" do
    plan = create(:plan, community: community)
    Subscription.create!(community: community, membership: member_membership,
                         plan: plan, status: "active")

    sign_in(admin, community)
    delete "/api/v1/admin/plans/#{plan.id}", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(json["hidden_instead"]).to be(true)
    expect(plan.reload.visible).to be(false)
  end

  it "refuses to delete a category that still has posts" do
    category = create(:category, community: community)
    create(:post, community: community, category: category, user: member)

    sign_in(admin, community)
    delete "/api/v1/admin/categories/#{category.id}", headers: headers_for(community)

    expect(response).to have_http_status(:conflict)
    expect(Category.exists?(category.id)).to be(true)
  end
end

RSpec.describe "Community settings", type: :request do
  let(:community) { create(:community, name: "Original") }
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let!(:owner_membership) { create(:membership, user: owner, community: community, role: "owner") }
  let!(:member_membership) { create(:membership, user: member, community: community) }

  before { ActsAsTenant.current_tenant = community }

  it "lets staff update the community" do
    sign_in(owner, community)
    patch "/api/v1/community",
          params: { community: { name: "Renamed" } }.to_json, headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(community.reload.name).to eq("Renamed")
  end

  # Regression: the staff check was once called inside the action, which rendered 403 and
  # then carried on and wrote anyway. A rendered error does not halt a method.
  it "refuses an ordinary member and leaves the record untouched" do
    sign_in(member, community)
    patch "/api/v1/community",
          params: { community: { name: "Hijacked" } }.to_json, headers: headers_for(community)

    expect(response).to have_http_status(:forbidden)
    expect(community.reload.name).to eq("Original")
  end

  it "compiles brand tokens for anyone, including signed-out visitors" do
    get "/api/v1/community/branding", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(json["css"]).to include("--brand-accent-h")
  end
end
