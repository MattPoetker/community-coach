# frozen_string_literal: true

module Search
  # Postgres full-text, ranked with a recency decay so a perfect match from 2023 does not
  # outrank a good match from this week. The Backend seam exists so a Meilisearch adapter
  # can be added later — but shipping two search backends in v1 would be a mistake.
  class Query
    HALF_LIFE_DAYS = 45.0

    def initialize(term, community:, limit: 25)
      @term = term.to_s.strip
      @community = community
      @limit = limit.clamp(1, 100)
    end

    def self.call(...) = new(...).call

    def call
      return { posts: [], lessons: [] } if @term.blank?

      { posts: posts, lessons: lessons }
    end

    private

    MATCH = "search_vector @@ websearch_to_tsquery('english', ?)"

    # `select` performs no bind substitution, so the ranking expression needs a sanitised
    # literal. The filter does support binds, and uses one — there is no reason to hand
    # Brakeman something that looks like interpolated SQL when a bind will do.
    def ranked_tsquery
      @ranked_tsquery ||= ActiveRecord::Base.sanitize_sql_array(
        ["websearch_to_tsquery('english', ?)", @term]
      )
    end

    def posts
      Post.kept
          .where(community: @community)
          .where(MATCH, @term)
          .select("posts.*, ts_rank_cd(search_vector, #{ranked_tsquery}) * #{decay} AS rank")
          .reorder(Arel.sql("rank DESC"))
          .limit(@limit)
          .includes(:user, :category)
    end

    def lessons
      Lesson.published
            .where(community: @community)
            .where(MATCH, @term)
            .limit(@limit)
            .includes(course_module: :course)
    end

    # exp(-age_days / half_life): recent content wins ties without burying the archive.
    def decay
      "exp(-EXTRACT(EPOCH FROM (NOW() - posts.last_activity_at)) / 86400.0 / #{HALF_LIFE_DAYS})"
    end
  end
end
