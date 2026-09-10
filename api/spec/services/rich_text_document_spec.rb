# frozen_string_literal: true

require "rails_helper"

RSpec.describe RichText::Document do
  it "extracts plain text for search and previews" do
    doc = described_class.from_plain_text("First para.\n\nSecond para.")
    expect(described_class.new(doc).to_plain_text).to include("First para.", "Second para.")
  end

  it "rejects an unknown node type rather than stripping it silently" do
    doc = { "type" => "doc", "content" => [{ "type" => "script", "content" => [] }] }
    expect { described_class.new(doc).validate! }
      .to raise_error(described_class::InvalidDocument, /unknown node type/)
  end

  it "rejects a javascript: link" do
    doc = { "type" => "doc", "content" => [
      { "type" => "text", "text" => "click",
        "marks" => [{ "type" => "link", "attrs" => { "href" => "javascript:alert(1)" } }] }
    ] }
    expect { described_class.new(doc).validate! }
      .to raise_error(described_class::InvalidDocument, /scheme/)
  end

  it "allows an ordinary https link" do
    doc = { "type" => "doc", "content" => [
      { "type" => "text", "text" => "docs",
        "marks" => [{ "type" => "link", "attrs" => { "href" => "https://example.com" } }] }
    ] }
    expect(described_class.new(doc).validate!).to be(true)
  end

  it "refuses a document nested past the depth limit" do
    deep = (1..20).reduce({ "type" => "text", "text" => "x" }) do |inner, _|
      { "type" => "paragraph", "content" => [inner] }
    end
    expect { described_class.new(deep).validate! }
      .to raise_error(described_class::InvalidDocument, /deeply/)
  end
end
