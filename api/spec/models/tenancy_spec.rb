# frozen_string_literal: true

require "rails_helper"

# The guard that makes multi-tenancy safe to work on.
#
# A model that forgets `acts_as_tenant :community` does not fail loudly — it quietly serves
# one community's rows to another. That is the single worst bug this codebase could ship,
# and it is exactly the kind a reviewer skims past. So it is a test instead.
RSpec.describe "Tenant scoping" do
  it "scopes every model to a community, or names it on the global allowlist" do
    Rails.application.eager_load!

    unscoped = ApplicationRecord.descendants.reject(&:abstract_class?).reject do |model|
      model.tenancy_exempt? ||
        model.name.start_with?("Solid") ||
        model.respond_to?(:scoped_by_tenant?)
    end

    expect(unscoped).to be_empty, <<~MESSAGE
      These models are neither tenant-scoped nor on the global allowlist:

        #{unscoped.map(&:name).join("\n  ")}

      Add `acts_as_tenant :community` to each, or list it in
      ApplicationRecord::GLOBAL_MODELS / SCOPED_VIA_PARENT with a reason.
    MESSAGE
  end

  it "does not return another community's rows when a tenant is set" do
    alpha = create(:community)
    beta = create(:community)
    create(:post, community: alpha, category: create(:category, community: alpha),
                  user: create(:user))
    create(:post, community: beta, category: create(:category, community: beta),
                  user: create(:user))

    ActsAsTenant.with_tenant(alpha) do
      expect(Post.count).to eq(1)
      expect(Post.first.community_id).to eq(alpha.id)
    end
  end

  it "refuses to query tenant-scoped models with no tenant set" do
    # The requirement is relaxed in the test environment so fixtures can span communities.
    # Turn it back on here, because this is the behaviour production depends on.
    original = ActsAsTenant.configuration.require_tenant
    ActsAsTenant.configuration.require_tenant = true

    expect { Post.count }.to raise_error(ActsAsTenant::Errors::NoTenantSet)
  ensure
    ActsAsTenant.configuration.require_tenant = original
  end
end
