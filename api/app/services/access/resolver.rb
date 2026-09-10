# frozen_string_literal: true

module Access
  # Answers one question: may this member *see* this thing?
  #
  # This is entitlement, deliberately separate from authorization. Pundit answers "may a
  # moderator lock this post" (a question about role); this answers "does their plan and
  # their drip schedule include this lesson" (a question about what they bought).
  # Conflating the two is how paywalls leak, so policies call into here rather than
  # reimplementing it.
  #
  # Rules are the `access_rule` jsonb shared by categories, courses and lessons:
  #
  #   { "type": "all_of", "rules": [ { "plan_in": ["pro"] }, { "min_level": 3 } ] }
  #
  # An empty rule means open to any active member.
  class Resolver
    Result = Struct.new(:granted, :reason, :detail, keyword_init: true) do
      def granted? = granted
    end

    GRANTED = Result.new(granted: true).freeze

    def initialize(membership, resource)
      @membership = membership
      @resource = resource
    end

    def self.call(...) = new(...).call

    def self.granted?(membership, resource) = call(membership, resource).granted?

    def call
      return deny("not_a_member") if @membership.nil?
      return deny("membership_#{@membership.status}") unless @membership.active?
      # Staff see everything in their own community; otherwise moderating a paid course
      # would require buying it.
      return GRANTED if @membership.staff?

      evaluate(rule)
    end

    private

    def rule = @resource.try(:access_rule).presence || {}

    def evaluate(node)
      return GRANTED if node.blank?

      case node["type"]
      when "any_of" then any_of(node)
      when "all_of", nil then all_of(node)
      else deny("unknown_rule_type", node["type"])
      end
    end

    def all_of(node)
      clauses(node).each do |clause|
        result = check(clause)
        return result unless result.granted?
      end
      GRANTED
    end

    def any_of(node)
      results = clauses(node).map { check(_1) }
      return GRANTED if results.empty? || results.any?(&:granted?)

      results.first
    end

    def clauses(node)
      list = node["rules"] || node["clauses"]
      return Array(list) if list

      # A bare hash of conditions is treated as all_of, which is what an author who wrote
      # `{"plan_in": ["pro"]}` plainly meant.
      node.except("type").map { |k, v| { k => v } }
    end

    def check(clause)
      key, value = clause.is_a?(Hash) ? clause.first : [clause, nil]

      case key.to_s
      when "plan_in" then check_plan(value)
      when "min_level" then check_level(value)
      when "drip_ready" then check_drip
      when "role_in" then check_role(value)
      else deny("unknown_rule", key)
      end
    end

    def check_plan(slugs)
      return GRANTED if Array(slugs).include?(@membership.plan_slug)

      deny("plan_required", Array(slugs))
    end

    # Inert until gamification ships in v2. The schema and the rule format already carry it
    # so enabling the feature is not a migration of every access_rule in the database.
    def check_level(minimum)
      return GRANTED if @membership.level >= minimum.to_i

      deny("level_required", minimum)
    end

    def check_drip
      return GRANTED unless @resource.respond_to?(:dripped_for?)
      return GRANTED if @resource.dripped_for?(@membership)

      deny("drip_pending", @resource.drip_available_at(@membership))
    end

    def check_role(roles)
      return GRANTED if Array(roles).include?(@membership.role)

      deny("role_required", Array(roles))
    end

    def deny(reason, detail = nil) = Result.new(granted: false, reason: reason, detail: detail)
  end
end
