# frozen_string_literal: true

require "rails_helper"

RSpec.describe Branding::Contrast do
  it "picks black rather than white on a light accent" do
    colour, ratio = described_class.best_on({ l: 0.88, c: 0.19, h: 100 })
    expect(colour).to eq(described_class::BLACK)
    expect(ratio).to be >= described_class::AA_BODY
  end

  it "picks white on a dark accent" do
    colour, = described_class.best_on({ l: 0.42, c: 0.13, h: 250 })
    expect(colour).to eq(described_class::WHITE)
  end

  it "clears every shipped preset's accent at AA" do
    Branding::Presets.all.each_value do |preset|
      accent = preset.fetch("accent").symbolize_keys
      _, ratio = described_class.best_on(accent)
      expect(ratio).to be >= described_class::AA_BODY,
                       "#{preset['name']} accent fails AA at #{ratio}:1"
    end
  end

  it "adjusts an accent that no text colour can clear" do
    bad = { l: 0.58, c: 0.15, h: 60 }
    colour, before = described_class.best_on(bad)
    next if before >= described_class::AA_BODY

    fixed = described_class.enforce(bad, colour, level: described_class::AA_BODY)
    _, after = described_class.best_on(fixed)
    expect(after).to be >= described_class::AA_BODY
    expect(fixed[:h]).to eq(bad[:h]) # the owner keeps their hue
  end
end
