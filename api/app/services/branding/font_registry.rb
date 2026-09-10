# frozen_string_literal: true

module Branding
  # The set of families a community may select. Two reasons it is a closed list
  # rather than a free-text field:
  #
  #   * The family name is interpolated into a Google Fonts URL and into CSS. An
  #     allowlist is the simplest complete defence against both injections.
  #   * Self-hosted installs can mirror these files locally for deployments with
  #     no third-party requests; an open field makes that impossible to support.
  #
  # Adding a family is a one-line PR, which is the right amount of friction.
  module FontRegistry
    FAMILIES = {
      # family => [variable axes / weights to request]
      "Archivo" => "wght@400;500;600;700",
      "Big Shoulders Display" => "wght@400;600;700;800",
      "Bodoni Moda" => "opsz,wght@6..96,400;6..96,500;6..96,700",
      "Bricolage Grotesque" => "opsz,wght@12..96,400;12..96,600;12..96,700",
      "Epilogue" => "wght@400;500;600;700",
      "Figtree" => "wght@400;500;600;700",
      "Hanken Grotesk" => "wght@400;500;600;700",
      "IBM Plex Mono" => "wght@400;500;600",
      "IBM Plex Sans" => "wght@400;500;600;700",
      "JetBrains Mono" => "wght@400;500;700",
      "Instrument Serif" => "ital@0;1",
      "Karla" => "wght@400;500;600;700",
      "Newsreader" => "opsz,wght@6..72,400;6..72,500;6..72,600",
      "Public Sans" => "wght@400;500;600;700",
      "Schibsted Grotesk" => "wght@400;500;600;700",
      "Spectral" => "wght@400;500;600"
    }.freeze

    def self.allowed?(family) = FAMILIES.key?(family.to_s)

    def self.stylesheet_url(*families)
      selected = families.flatten.compact.uniq.select { allowed?(_1) }
      return nil if selected.empty?

      query = selected.map { "family=#{ERB::Util.url_encode(_1)}:#{FAMILIES.fetch(_1)}" }
      "https://fonts.googleapis.com/css2?#{query.join('&')}&display=swap"
    end
  end
end
