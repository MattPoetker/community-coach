# frozen_string_literal: true

module Access
  # Raised rather than rendered.
  #
  # `render` inside an action sets the response but does not stop the method — so a
  # controller that rendered 403 and carried on would still run the lines below it, which
  # for a lesson means minting a signed video URL for someone who was just refused. An
  # exception is the only construct that actually halts.
  class Denied < StandardError
    attr_reader :result

    def initialize(result)
      @result = result
      super(Messages.for(result))
    end
  end
end
