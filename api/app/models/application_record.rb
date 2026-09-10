# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Every model must be in exactly one of three buckets, and spec/models/tenancy_spec.rb
  # enforces it. A model that silently falls through serves one community's rows to
  # another — the worst bug this codebase could ship, and precisely the kind a reviewer
  # skims past. So it is a test rather than a convention.

  # 1. Genuinely global: identity, the tenant table itself, and infrastructure.
  GLOBAL_MODELS = %w[
    User Session Community CustomDomain WebhookEvent PushSubscription AuditLog
  ].freeze

  # 2. Reachable only through a tenant-scoped parent, so they carry no community_id of
  #    their own. A poll cannot be loaded except through its post, and that post is
  #    scoped — adding a redundant column would create a second source of truth that
  #    could disagree with the first.
  SCOPED_VIA_PARENT = %w[Poll PollOption PollVote].freeze

  # 3. Everything else declares `acts_as_tenant :community`.

  def self.tenancy_exempt? = GLOBAL_MODELS.include?(name) || SCOPED_VIA_PARENT.include?(name)
end
