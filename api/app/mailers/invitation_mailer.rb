# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(invitation, raw_token)
    @invitation = invitation
    @community = invitation.community
    @url = "#{app_url}/join?invitation=#{raw_token}"

    mail(to: invitation.email_address,
         subject: "#{@invitation.invited_by.name} invited you to #{@community.name}") do |format|
      format.text { render plain: body_text }
    end
  end

  private

  def app_url = ENV.fetch("APP_URL", "http://localhost:3000")

  def body_text
    <<~TEXT
      #{@invitation.invited_by.name} has invited you to join #{@community.name}.

      #{@community.tagline}

      Accept the invitation:
      #{@url}

      The link expires on #{@invitation.expires_at.to_fs(:long)}.
    TEXT
  end
end
