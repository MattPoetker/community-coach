# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  # Jobs run outside a request, so nothing has set the tenant. Every job that touches
  # tenant-scoped data must establish it explicitly or acts_as_tenant will raise.
  def with_community(community_id)
    community = Community.find(community_id)
    ActsAsTenant.with_tenant(community) { yield community }
  end
end
