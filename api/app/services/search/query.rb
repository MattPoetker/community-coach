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

    # `select` performs no bind substitution, so the query is sanitised once here and the
    # resulting literal is reused in both the filter and the ranking expression.
    def tsquery
      @tsquery ||= ActiveRecord::Base.sanitize_sql_array(
        ["websearch_to_tsquery('english', ?)", @term]
      )
    end

    def posts
      Post.kept
          .where(community: @community)
          .where("search_vector @@ #{tsquery}")
          .select("posts.*, ts_rank_cd(search_vector, #{tsquery}) * #{decay} AS rank")
          .reorder(Arel.sql("rank DESC"))
          .limit(@limit)
          .includes(:user, :category)
    end

    def lessons
      Lesson.published
            .where(community: @community)
            .where("search_vector @@ #{tsquery}")
            .limit(@limit)
            .includes(course_module: :course)
    end

    # exp(-age_days / half_life): recent content wins ties without burying the archive.
    def decay
      "exp(-EXTRACT(EPOCH FROM (NOW() - posts.last_activity_at)) / 86400.0 / #{HALF_LIFE_DAYS})"
    end
  end
end
