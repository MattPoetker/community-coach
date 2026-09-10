# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    @url = "#{app_url}/confirm?token=#{user.confirmation_token}"
    mail(to: user.email_address, subject: "Confirm your email") do |format|
      format.text { render plain: confirmation_body }
    end
  end

  def password_reset(user)
    @user = user
    @url = "#{app_url}/reset?token=#{user.password_reset_token}"
    mail(to: user.email_address, subject: "Reset your password") do |format|
      format.text { render plain: reset_body }
    end
  end

  private

  def app_url = ENV.fetch("APP_URL", "http://localhost:3000")

  def confirmation_body
    <<~TEXT
      Hello #{@user.name},

      Confirm your email address to finish setting up your account:

      #{@url}

      If you did not create an account, ignore this message.
    TEXT
  end

  def reset_body
    <<~TEXT
      Hello #{@user.name},

      Use this link to choose a new password. It works once and expires in two hours.

      #{@url}

      If you did not ask for this, nothing has changed and you can ignore it.
    TEXT
  end
end
