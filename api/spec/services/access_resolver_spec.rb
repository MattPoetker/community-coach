# frozen_string_literal: true

require "rails_helper"

RSpec.describe Access::Resolver do
  let(:community) { create(:community) }
  let(:membership) { create(:membership, community: community) }

  def resource_with(rule) = Struct.new(:access_rule).new(rule)

  around { |example| ActsAsTenant.with_tenant(community) { example.run } }

  it "grants when there is no rule" do
    expect(described_class.granted?(membership, resource_with({}))).to be(true)
  end

  it "denies a non-member" do
    result = described_class.call(nil, resource_with({}))
    expect(result.granted?).to be(false)
    expect(result.reason).to eq("not_a_member")
  end

  it "denies a suspended member even with no rule" do
    membership.update!(status: "suspended")
    expect(described_class.call(membership, resource_with({})).reason).to eq("membership_suspended")
  end

  it "grants staff regardless of plan, so moderating a paid course does not require buying it" do
    membership.update!(role: "moderator")
    rule = { "plan_in" => %w[inner-circle] }
    expect(described_class.granted?(membership, resource_with(rule))).to be(true)
  end

  it "denies a member whose plan is not listed" do
    result = described_class.call(membership, resource_with({ "plan_in" => %w[inner-circle] }))
    expect(result.granted?).to be(false)
    expect(result.reason).to eq("plan_required")
  end

  it "grants a member on a listed plan" do
    plan = create(:plan, community: community, slug: "inner-circle")
    Subscription.create!(community: community, membership: membership, plan: plan, status: "active")

    expect(described_class.granted?(membership, resource_with({ "plan_in" => %w[inner-circle] }))).to be(true)
  end

  it "treats a bare hash of conditions as all_of" do
    plan = create(:plan, community: community, slug: "pro")
    Subscription.create!(community: community, membership: membership, plan: plan, status: "active")

    rule = { "plan_in" => %w[pro], "min_level" => 1 }
    expect(described_class.granted?(membership, resource_with(rule))).to be(true)
  end

  it "requires only one branch of any_of" do
    rule = { "type" => "any_of", "rules" => [{ "plan_in" => %w[nope] }, { "min_level" => 1 }] }
    expect(described_class.granted?(membership, resource_with(rule))).to be(true)
  end

  describe "drip" do
    let(:course_module) { create(:course_module, community: community) }

    it "withholds a lesson until the drip window has passed" do
      lesson = create(:lesson, community: community, course_module: course_module,
                               drip_kind: "days_after_join", drip_days: 30,
                               access_rule: { "drip_ready" => true })
      membership.update!(joined_at: 5.days.ago)

      result = described_class.call(membership, lesson)
      expect(result.granted?).to be(false)
      expect(result.reason).to eq("drip_pending")
    end

    it "releases it once enough days have passed" do
      lesson = create(:lesson, community: community, course_module: course_module,
                               drip_kind: "days_after_join", drip_days: 30,
                               access_rule: { "drip_ready" => true })
      membership.update!(joined_at: 45.days.ago)

      expect(described_class.granted?(membership, lesson)).to be(true)
    end
  end
end
