# frozen_string_literal: true

# Demo data. A fresh install that opens onto an empty shell shows nothing about what the
# product does, so `bin/setup` seeds a community that looks like a real one.
#
# Idempotent: safe to re-run.
#
# These accounts share one published password. That is fine for a laptop and a disaster on
# a public host, so seeding refuses to run in production unless you insist — a self-hoster
# who runs `rails db:seed` by reflex should not end up with five known logins.
if Rails.env.production? && ENV["SEED_DEMO_DATA"] != "i-understand-these-are-public-logins"
  abort <<~MESSAGE
    Refusing to seed demo data in production.

    These seeds create accounts with a password published in the README. If you genuinely
    want them on a production host — a demo instance, say — re-run with:

      SEED_DEMO_DATA=i-understand-these-are-public-logins bin/rails db:seed
  MESSAGE
end

ActsAsTenant.without_tenant do
  community = Community.find_or_create_by!(slug: "momentum") do |c|
    c.name = "Momentum Collective"
    c.tagline = "Group coaching for independent consultants"
    c.description = "Stop selling days. Start selling outcomes."
    c.privacy = "public"
    c.currency = "GBP"
    c.timezone = "Europe/London"
    c.branding = { "preset" => "kiln" }
    c.published_at = Time.current
  end

  ActsAsTenant.with_tenant(community) do
    people = [
      { email: "sara@example.com", name: "Sara Kowalczyk", role: "owner" },
      { email: "james@example.com", name: "James Toweel", role: "member" },
      { email: "mira@example.com", name: "Mira Okonkwo", role: "member" },
      { email: "rachel@example.com", name: "Rachel Byrne", role: "moderator" },
      { email: "daniel@example.com", name: "Daniel Osei", role: "member" }
    ]

    users = people.map do |person|
      user = User.find_or_initialize_by(email_address: person[:email])
      user.assign_attributes(name: person[:name], password: "correct-horse-battery",
                             confirmed_at: Time.current, timezone: "Europe/London")
      user.save!
      Membership.find_or_create_by!(user: user, community: community) do |m|
        m.role = person[:role]
        m.status = "active"
        m.joined_at = rand(40..400).days.ago
      end
      user
    end
    sara, james, mira, rachel, daniel = users

    categories = {
      "announcements" => ["Announcements", "admins"],
      "wins" => ["Wins", "all"],
      "ask" => ["Ask the Room", "all"],
      "accountability" => ["Accountability", "all"],
      "resources" => ["Resources", "all"]
    }.each_with_index.to_h do |(slug, (name, permission)), index|
      [slug, Category.find_or_create_by!(community: community, slug: slug) do |c|
        c.name = name
        c.post_permission = permission
        c.position = index
      end]
    end

    doc = ->(text) { RichText::Document.from_plain_text(text) }

    posts = [
      { user: sara, category: "announcements", kind: "announcement", pinned: true,
        title: "October cohort: hot seats open Thursday",
        body: "Six slots, first come. Bring a live pricing problem — an actual proposal " \
              "you have not sent yet, not a hypothetical.\n\nLast round we rewrote four " \
              "scopes on the call and three of them closed inside a fortnight." },
      { user: james, category: "wins", kind: "discussion",
        title: "Signed at £4,200/mo after eighteen months of day rates",
        body: "The thing that moved it was dropping the hourly line entirely from the " \
              "proposal.\n\nI sent three scoped outcomes with one price and said nothing " \
              "about days. They picked the middle one in a day and a half." },
      { user: mira, category: "ask", kind: "discussion",
        title: "Client wants to move from retainer back to project work",
        body: "Nine months in, new procurement lead, wants everything itemised.\n\nDo I " \
              "hold the line or take the project and rebuild the retainer later?" },
      { user: rachel, category: "accountability", kind: "discussion",
        title: "Pod 7 has gone eleven weeks without a missed check-in",
        body: "Five members, one shared doc, no software. The method is in the thread." },
      { user: daniel, category: "resources", kind: "discussion",
        title: "Nine proposal templates, ranked by what they actually closed",
        body: "Contributed by members who have priced past £100k. Figures included." }
    ].map.with_index do |attrs, index|
      post = Post.find_or_initialize_by(community: community, title: attrs[:title])
      post.assign_attributes(
        user: attrs[:user], category: categories.fetch(attrs[:category]),
        kind: attrs[:kind], body: doc.call(attrs[:body]),
        pinned_at: attrs[:pinned] ? Time.current : nil,
        last_activity_at: index.hours.ago
      )
      post.save!
      post
    end

    Comment.find_or_create_by!(post: posts[2], user: james, parent: nil) do |c|
      c.community = community
      c.body = doc.call("Had this exact thing in 2024. I itemised, and within two quarters " \
                        "I was being compared to a contractor day rate. Would not do it again.")
    end
    Comment.find_or_create_by!(post: posts[2], user: sara, parent: nil) do |c|
      c.community = community
      c.body = doc.call("Third option: give procurement the format they need, but itemise " \
                        "outcomes rather than hours. Same total, no hourly comparison.")
    end

    course = Course.find_or_create_by!(community: community, slug: "positioning-sprint") do |c|
      c.title = "The Positioning Sprint"
      c.description = "Nine lessons on deciding who you are not for."
      c.published_at = Time.current
    end

    module_one = CourseModule.find_or_create_by!(community: community, course: course,
                                                 title: "Deciding") { _1.position = 0 }
    [
      ["Who you are not for", 0, "none", nil],
      ["Auditing your last ten enquiries", 1, "none", nil],
      ["Writing the one-line answer", 2, "none", nil],
      ["Testing it on a stranger", 3, "days_after_join", 30]
    ].each do |title, position, drip_kind, drip_days|
      Lesson.find_or_create_by!(community: community, course_module: module_one,
                                slug: title.parameterize) do |l|
        l.title = title
        l.position = position
        l.drip_kind = drip_kind
        l.drip_days = drip_days
        l.published_at = Time.current
        l.body = doc.call("Lesson content goes here.")
      end
    end

    [
      ["Free", "free", 0, 0],
      ["Practice", "practice", 8_900, 14],
      ["Inner Circle", "inner-circle", 34_900, 0]
    ].each_with_index do |(name, slug, cents, trial), index|
      Plan.find_or_create_by!(community: community, slug: slug) do |p|
        p.name = name
        p.amount_cents = cents
        p.trial_days = trial
        p.currency = "GBP"
        p.position = index
        p.features = ["Community feed", "Course library", "Weekly office hours"].first(index + 1)
      end
    end

    event = Event.find_or_create_by!(community: community, title: "Pricing hot seats") do |e|
      e.host = sara
      e.starts_at = Time.current.next_occurring(:thursday).change(hour: 18)
      e.duration_minutes = 60
      e.timezone = "Europe/London"
      e.rrule = "FREQ=WEEKLY;BYDAY=TH"
      e.location_kind = "zoom"
      e.location_url = "https://example.zoom.us/j/000000"
    end
    event.materialise_occurrences

    puts "Seeded #{community.name}: #{Membership.count} members, #{Post.count} posts, " \
         "#{Course.count} course, #{Plan.count} plans, #{EventOccurrence.count} occurrences."
    puts "Sign in as sara@example.com / correct-horse-battery"
  end
end
