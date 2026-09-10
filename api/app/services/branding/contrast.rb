# frozen_string_literal: true

module Branding
  # WCAG 2.1 relative-luminance contrast, plus the OKLCH conversion needed to
  # evaluate brand inputs before they are ever rendered.
  #
  # This exists so a community owner cannot ship an unreadable interface. An
  # owner picking "a nice yellow" for their accent is a normal thing to happen;
  # white-on-yellow buttons reaching their members is not.
  module Contrast
    AA_BODY  = 4.5
    AA_LARGE = 3.0

    module_function

    # @param oklch [Hash] { l:, c:, h: } — l in 0..1, c in 0..0.4, h in degrees
    # @return [Array<Float>] linear sRGB, each channel 0..1, gamut-clipped
    def oklch_to_linear_srgb(oklch)
      l, c, h = oklch.values_at(:l, :c, :h).map(&:to_f)
      hr = h * Math::PI / 180.0
      a  = c * Math.cos(hr)
      b  = c * Math.sin(hr)

      l_ = l + 0.3963377774 * a + 0.2158037573 * b
      m_ = l - 0.1055613458 * a - 0.0638541728 * b
      s_ = l - 0.0894841775 * a - 1.2914855480 * b

      lc = l_**3
      mc = m_**3
      sc = s_**3

      [
        (+4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc),
        (-1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc),
        (-0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc)
      ].map { |v| v.clamp(0.0, 1.0) }
    end

    # WCAG relative luminance. Linear sRGB is already the linearised space the
    # formula wants, so no extra gamma step here.
    def relative_luminance(oklch)
      r, g, b = oklch_to_linear_srgb(oklch)
      (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    end

    def ratio(fg, bg)
      l1 = relative_luminance(fg)
      l2 = relative_luminance(bg)
      hi, lo = [l1, l2].minmax.reverse
      ((hi + 0.05) / (lo + 0.05)).round(3)
    end

    def passes?(fg, bg, level: AA_BODY)
      ratio(fg, bg) >= level
    end

    WHITE = { l: 0.99, c: 0.005, h: 0 }.freeze
    BLACK = { l: 0.17, c: 0.01,  h: 0 }.freeze

    # Which of white/near-black to set on a filled accent block. Picks whichever
    # wins, and reports the ratio so the caller can warn if even the winner is
    # marginal.
    def best_on(background)
      white = ratio(WHITE, background)
      black = ratio(BLACK, background)
      white >= black ? [WHITE, white] : [BLACK, black]
    end

    # Walk lightness until `colour` clears `level` against `background`.
    # Direction is chosen by which way has headroom. Returns the original when
    # no adjustment within the ramp can satisfy the requirement, so the caller
    # decides whether that is a warning or a hard failure.
    def enforce(colour, background, level: AA_BODY, step: 0.02, limit: 40)
      return colour if passes?(colour, background, level: level)

      direction = relative_luminance(background) > 0.5 ? -1 : 1
      candidate = colour.dup

      limit.times do
        candidate = candidate.merge(l: (candidate[:l] + (direction * step)).clamp(0.0, 1.0))
        return candidate if passes?(candidate, background, level: level)
        break if candidate[:l] <= 0.0 || candidate[:l] >= 1.0
      end

      colour
    end
  end
end
