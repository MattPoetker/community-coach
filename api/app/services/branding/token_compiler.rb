# frozen_string_literal: true

module Branding
  # Turns a community's ~14 brand inputs into the Layer 0 custom properties the
  # stylesheet needs, and emits them as one <style> block.
  #
  # Two guarantees this class exists to make:
  #
  #   1. An owner never has to touch code to rebrand. They set values; this
  #      compiles them.
  #   2. An owner cannot produce an unreadable interface. Every text/surface
  #      pair is checked against WCAG AA before it is emitted, and the accent's
  #      contrast colour is chosen rather than assumed.
  #
  # Only Layer 0 is emitted. The derived ramps stay in CSS so the admin brand
  # editor can preview a change instantly without a round trip.
  class TokenCompiler
    PRESETS = %w[kiln meridian signal ledger].freeze
    FALLBACK_STACKS = {
      "display" => %w[Helvetica\ Neue Arial sans-serif],
      "body" => %w[Helvetica\ Neue Arial sans-serif],
      "mono" => %w[ui-monospace SFMono-Regular monospace]
    }.freeze

    # Anything not on this list is ignored rather than interpolated, which is
    # what keeps a jsonb column out of reach of CSS injection.
    NUMERIC_INPUTS = {
      "radiusScale" => { var: "--brand-radius-scale", range: (0.0..3.0) },
      "density" => { var: "--brand-density", range: (0.75..1.5) },
      "typeRatio" => { var: "--brand-type-ratio", range: (1.05..1.5) }
    }.freeze

    Result = Struct.new(:css, :warnings, keyword_init: true)

    def initialize(branding, preset_defaults:)
      @branding = branding.to_h.deep_stringify_keys
      @defaults = preset_defaults.to_h.deep_stringify_keys
      @warnings = []
    end

    def self.call(...) = new(...).call

    def call
      declarations = []
      declarations.concat(colour_declarations)
      declarations.concat(font_declarations)
      declarations.concat(numeric_declarations)

      Result.new(css: wrap(declarations), warnings: @warnings)
    end

    private

    def merged(key) = @branding.fetch(key) { @defaults[key] }

    def colour_declarations
      accent = symbolize(merged("accent"))
      neutral = symbolize(merged("neutral"))

      contrast, achieved = Contrast.best_on(accent)
      if achieved < Contrast::AA_BODY
        # Rather than ship a failing button, darken the accent itself until the
        # winning text colour clears AA. The owner keeps their hue.
        accent = Contrast.enforce(accent, contrast, level: Contrast::AA_BODY)
        contrast, achieved = Contrast.best_on(accent)
        @warnings << "Accent adjusted to reach WCAG AA on its own label " \
                     "(now #{achieved}:1). Pick a darker or lighter hue to avoid this."
      end

      [
        css_var("--brand-accent-l", format("%.4f", accent[:l])),
        css_var("--brand-accent-c", format("%.4f", accent[:c])),
        css_var("--brand-accent-h", format("%.2f", accent[:h])),
        css_var("--brand-neutral-h", format("%.2f", neutral[:h])),
        css_var("--brand-neutral-c", format("%.4f", neutral[:c])),
        css_var("--a-contrast", oklch(contrast)),
        # The scrim behind text on media must oppose whichever contrast colour won.
        # The compiler already made that decision, so it emits the matching scrim
        # rather than leaving each theme to guess.
        css_var("--media-scrim", scrim_for(contrast, accent))
      ]
    end

    def font_declarations
      fonts = merged("fonts").to_h

      %w[display body mono].filter_map do |role|
        family = fonts[role].presence or next
        unless FontRegistry.allowed?(family)
          @warnings << "Font #{family.inspect} is not in the font registry; falling back."
          next
        end
        css_var("--brand-font-#{role}", font_stack(family, role))
      end
    end

    def numeric_declarations
      structure = merged("structure").to_h

      NUMERIC_INPUTS.filter_map do |key, config|
        raw = structure[key]
        next if raw.blank?

        value = Float(raw, exception: false)
        next @warnings << "#{key} must be a number; ignored." if value.nil?

        clamped = value.clamp(config[:range].begin, config[:range].end)
        if clamped != value
          @warnings << "#{key} clamped from #{value} to #{clamped}."
        end
        css_var(config[:var], format("%.3f", clamped))
      end
    end

    # Quote any family whose name contains a space, and always append a real
    # fallback stack — a webfont that fails to load must not drop the page to
    # the browser default.
    def font_stack(family, role)
      quoted = family.match?(/\A[a-zA-Z][a-zA-Z0-9]*\z/) ? family : %("#{family}")
      [quoted, *FALLBACK_STACKS.fetch(role)].map { |f| f.include?(" ") && !f.start_with?('"') ? %("#{f}") : f }.join(", ")
    end

    # A dark accent took white text, so the scrim darkens; a light accent took near-black
    # text, so it lightens. Both carry a trace of the accent hue to stay in family.
    def scrim_for(contrast, accent)
      if contrast == Contrast::WHITE
        format("oklch(0.16 0.02 %.2f / 0.72)", accent[:h])
      else
        format("oklch(0.97 0.01 %.2f / 0.78)", accent[:h])
      end
    end

    def oklch(colour)
      format("oklch(%.4f %.4f %.2f)", colour[:l], colour[:c], colour[:h])
    end

    def css_var(name, value) = "#{name}: #{value};"

    def symbolize(hash)
      hash.to_h.symbolize_keys.transform_values(&:to_f)
    end

    def wrap(declarations)
      <<~CSS
        :root{#{declarations.join}}
      CSS
    end
  end
end
