# frozen_string_literal: true

require "rails_helper"

# The test this product most needs to keep passing.
#
# A paywall that merely hides a lesson in the UI is not a paywall. These assert that a
# member without the plan is refused the lesson *and* never receives a playback URL — the
# second half being the one that actually costs money when it regresses, because a leaked
# signed URL can be pasted anywhere.
RSpec.describe "Paywalled content", type: :request do
  let(:community) { create(:community) }
  let(:free_user) { create(:user) }
  let(:paid_user) { create(:user) }
  let!(:free_membership) { create(:membership, user: free_user, community: community) }
  let!(:paid_membership) { create(:membership, user: paid_user, community: community) }

  let(:course) { create(:course, community: community) }
  let(:course_module) { create(:course_module, community: community, course: course) }
  let(:video) { VideoAsset.create!(community: community, status: "ready", provider: "local") }
  let!(:paid_lesson) do
    create(:lesson, community: community, course_module: course_module, video_asset: video,
                    access_rule: { "plan_in" => %w[inner-circle] })
  end

  before do
    ActsAsTenant.current_tenant = community
    plan = create(:plan, community: community, slug: "inner-circle")
    Subscription.create!(community: community, membership: paid_membership,
                         plan: plan, status: "active")
  end

  it "refuses the lesson to a member without the plan" do
    sign_in(free_user, community)
    get "/api/v1/lessons/#{paid_lesson.id}", headers: headers_for(community)

    expect(response).to have_http_status(:forbidden)
    expect(json.dig("error", "code")).to eq("plan_required")
  end

  it "never returns a playback URL to a member without the plan" do
    sign_in(free_user, community)
    get "/api/v1/lessons/#{paid_lesson.id}", headers: headers_for(community)

    expect(response.body).not_to include("playback_url")
    expect(response.body).not_to match(/m3u8|X-Amz-Signature/)
  end

  it "serves the lesson to a member on the right plan" do
    sign_in(paid_user, community)
    allow_any_instance_of(Video::Providers::Local)
      .to receive(:playback_url).and_return("https://cdn.example/signed.m3u8")

    get "/api/v1/lessons/#{paid_lesson.id}", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
    expect(json["playback_url"]).to eq("https://cdn.example/signed.m3u8")
  end

  it "refuses to record progress against a lesson the member cannot access" do
    sign_in(free_user, community)
    put "/api/v1/lessons/#{paid_lesson.id}/progress",
        params: { seconds_watched: 30 }.to_json, headers: headers_for(community)

    expect(response).to have_http_status(:forbidden)
    expect(LessonProgress.count).to eq(0)
  end

  it "withholds a dripped lesson until its window opens, then releases it" do
    dripped = create(:lesson, community: community, course_module: course_module,
                              drip_kind: "days_after_join", drip_days: 30,
                              access_rule: { "drip_ready" => true })
    free_membership.update!(joined_at: 5.days.ago)

    sign_in(free_user, community)
    get "/api/v1/lessons/#{dripped.id}", headers: headers_for(community)
    expect(response).to have_http_status(:forbidden)
    expect(json.dig("error", "code")).to eq("drip_pending")

    free_membership.update!(joined_at: 40.days.ago)
    get "/api/v1/lessons/#{dripped.id}", headers: headers_for(community)
    expect(response).to have_http_status(:ok)
  end

  it "lets staff see paid content without buying it" do
    staff = create(:user)
    create(:membership, user: staff, community: community, role: "moderator")
    allow_any_instance_of(Video::Providers::Local).to receive(:playback_url).and_return("x")

    sign_in(staff, community)
    get "/api/v1/lessons/#{paid_lesson.id}", headers: headers_for(community)

    expect(response).to have_http_status(:ok)
  end
end
