# frozen_string_literal: true

module Branding
  # The shipped theme presets, loaded from the same JSON the frontend reads so the two can
  # never disagree about what "kiln" means.
  module Presets
    PATH = Rails.root.join("../web/styles/themes").freeze
    DEFAULT = "kiln"

    class << self
      def all
        @all ||= Dir[PATH.join("*.json")].to_h do |file|
          data = JSON.parse(File.read(file))
          [data.fetch("key"), data]
        end.freeze
      rescue Errno::ENOENT
        {}
      end

      def fetch(key) = all.fetch(key.to_s) { all.fetch(DEFAULT, {}) }
      def keys = all.keys
      def exists?(key) = all.key?(key.to_s)
    end
  end
end
