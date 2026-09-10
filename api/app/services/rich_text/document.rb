# frozen_string_literal: true

module RichText
  # Posts and comments are stored as a constrained ProseMirror document rather than HTML.
  # Sanitising HTML at render time is where XSS bugs live; accepting only a known node
  # vocabulary and rendering from it removes the class rather than patching it.
  class Document
    ALLOWED_NODES = %w[doc paragraph text heading bulletList orderedList listItem
                       blockquote codeBlock hardBreak image horizontalRule mention].freeze
    ALLOWED_MARKS = %w[bold italic strike code link].freeze
    MAX_DEPTH = 12

    class InvalidDocument < StandardError; end

    def initialize(json)
      @doc = json.is_a?(String) ? JSON.parse(json) : (json || {})
    end

    def to_plain_text(node = @doc, depth = 0)
      return "" if depth > MAX_DEPTH || !node.is_a?(Hash)

      case node["type"]
      when "text" then node["text"].to_s
      when "hardBreak" then "\n"
      when "mention" then "@#{node.dig('attrs', 'label')}"
      else
        children = Array(node["content"]).map { to_plain_text(_1, depth + 1) }
        block?(node["type"]) ? "#{children.join}\n" : children.join
      end
    end

    def mentioned_usernames(node = @doc, depth = 0, found = [])
      return found if depth > MAX_DEPTH || !node.is_a?(Hash)

      found << node.dig("attrs", "id") if node["type"] == "mention"
      Array(node["content"]).each { mentioned_usernames(_1, depth + 1, found) }
      found.compact.uniq
    end

    # Rejects unknown nodes and marks outright rather than stripping them silently — a
    # client sending something we do not understand is a bug worth surfacing, not hiding.
    def validate!(node = @doc, depth = 0)
      raise InvalidDocument, "document nested too deeply" if depth > MAX_DEPTH
      return true unless node.is_a?(Hash)

      type = node["type"]
      raise InvalidDocument, "unknown node type: #{type}" if type && ALLOWED_NODES.exclude?(type)

      Array(node["marks"]).each do |mark|
        name = mark.is_a?(Hash) ? mark["type"] : mark
        raise InvalidDocument, "unknown mark: #{name}" if ALLOWED_MARKS.exclude?(name)
        validate_link!(mark) if name == "link"
      end

      Array(node["content"]).each { validate!(_1, depth + 1) }
      true
    end

    def self.from_plain_text(text)
      paragraphs = text.to_s.split(/\n{2,}/).map do |para|
        { "type" => "paragraph", "content" => [{ "type" => "text", "text" => para.strip }] }
      end
      { "type" => "doc", "content" => paragraphs.presence || [{ "type" => "paragraph" }] }
    end

    private

    def block?(type) = %w[paragraph heading listItem blockquote codeBlock].include?(type)

    # javascript: and data: hrefs are the whole reason link marks need checking.
    def validate_link!(mark)
      href = mark.dig("attrs", "href").to_s
      return if href.blank?

      uri = URI.parse(href)
      raise InvalidDocument, "unsupported link scheme" unless %w[http https mailto].include?(uri.scheme)
    rescue URI::InvalidURIError
      raise InvalidDocument, "malformed link"
    end
  end
end
