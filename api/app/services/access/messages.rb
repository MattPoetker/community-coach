# frozen_string_literal: true

module Access
  # Member-facing wording for a denial. Written from the member's side of the screen: what
  # they can do about it, never what the rule engine concluded.
  module Messages
    module_function

    def for(result)
      case result.reason
      when "not_a_member" then "Join this community to see that."
      when "membership_pending" then "Your request to join is still being reviewed."
      when "membership_suspended" then "Your membership is suspended. Contact the host."
      when "membership_cancelled" then "Your membership has ended. Rejoin to get access back."
      when "plan_required" then "That is included with #{plan_names(result.detail)}."
      when "level_required" then "Reach level #{result.detail} to unlock that."
      when "drip_pending" then drip_message(result.detail)
      when "role_required" then "Only #{result.detail.to_sentence} can see that."
      else "You do not have access to that."
      end
    end

    def plan_names(slugs) = Array(slugs).map(&:humanize).to_sentence(two_words_connector: " or ")

    def drip_message(available_at)
      return "That unlocks later in the programme." if available_at.blank?

      "That unlocks on #{available_at.to_fs(:long)}."
    end
  end
end
