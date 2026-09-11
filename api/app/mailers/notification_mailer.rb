# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def instant(notification)
    @notification = notification
    @user = notification.user
    return if @user.email_address.blank?

    mail(to: @user.email_address, subject: subject_for(notification)) do |format|
      format.text { render plain: instant_body }
    end
  end

  # One email a day rather than one per event. The alternative is the reason people turn
  # community email off entirely and then miss the things that mattered.
  def digest(user, community, notifications)
    @user = user
    @community = community
    @notifications = notifications

    mail(to: user.email_address,
         subject: "#{notifications.size} updates from #{community.name}") do |format|
      format.text { render plain: digest_body }
    end
  end

  private

  def subject_for(notification)
    case notification.kind
    when "reply" then "New reply: #{notification.data['post_title']}"
    when "mention" then "#{notification.actor&.name} mentioned you"
    when "reaction" then "#{notification.actor&.name} liked your post"
    when "event_reminder" then "Starting soon: #{notification.data['title']}"
    else "New activity in #{notification.community.name}"
    end
  end

  def instant_body
    <<~TEXT
      #{subject_for(@notification)}

      #{@notification.data['excerpt']}

      #{ENV.fetch('APP_URL', 'http://localhost:3000')}/notifications

      Change what you hear about: #{ENV.fetch('APP_URL', 'http://localhost:3000')}/settings/notifications
    TEXT
  end

  def digest_body
    lines = @notifications.map { "  · #{subject_for(_1)}" }.join("\n")
    <<~TEXT
      Here is what happened in #{@community.name} today.

      #{lines}

      #{ENV.fetch('APP_URL', 'http://localhost:3000')}/notifications
    TEXT
  end
end
