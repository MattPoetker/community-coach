# frozen_string_literal: true

module Notifications
  # Fan-out on write, deduped per (user, subject, kind) inside a window so ten likes on one
  # post produce one incrementing row rather than ten inbox entries.
  module FanOut
    module_function

    def new_post(post)
      recipients = Membership.active
                             .where(community_id: post.community_id)
                             .where.not(user_id: post.user_id)
                             .pluck(:user_id)

      # Only for announcements — a notification for every post in a busy community is how
      # people turn notifications off entirely.
      return unless post.kind == "announcement"

      deliver_many(recipients, kind: "new_post", actor: post.user, subject: post,
                   data: { title: post.title })
    end

    def new_comment(comment)
      post = comment.post
      recipients = ThreadSubscription.audible
                                     .where(subject: post)
                                     .where.not(user_id: comment.user_id)
                                     .pluck(:user_id)

      deliver_many(recipients, kind: "reply", actor: comment.user, subject: post,
                   data: { post_title: post.title, excerpt: comment.body_text.truncate(140) })

      notify_mentions(comment)
    end

    def reaction(reactable, actor)
      return if reactable.user_id == actor.id

      Notification.deliver!(user: reactable.user, kind: "reaction", actor: actor,
                            subject: reactable, data: {})
    end

    def notify_mentions(source)
      handles = RichText::Document.new(source.body).mentioned_usernames
      return if handles.empty?

      users = User.where(id: handles).where.not(id: source.user_id)
      users.each do |user|
        next unless Membership.active.exists?(user: user, community_id: source.community_id)

        Notification.deliver!(user: user, kind: "mention", actor: source.user,
                              subject: source, data: {})
      end
    end

    def deliver_many(user_ids, kind:, actor:, subject:, data:)
      User.where(id: user_ids).find_each do |user|
        Notification.deliver!(user: user, kind: kind, actor: actor, subject: subject, data: data)
      end
    end
  end
end
