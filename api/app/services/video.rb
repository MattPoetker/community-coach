# frozen_string_literal: true

# Pluggable video backend, chosen by VIDEO_PROVIDER.
#
# `local` transcodes with ffmpeg on a worker and serves signed HLS from object storage. It
# is the default because a self-hoster should not need a third-party account to publish a
# lesson — but it is genuinely heavy, so the external adapters exist and the docs say when
# to reach for them.
module Video
  class UnknownProvider < StandardError; end

  module_function

  def provider
    @provider ||= build(ENV.fetch("VIDEO_PROVIDER", "local"))
  end

  def reset! = @provider = nil

  def build(name)
    case name.to_s
    when "local" then Providers::Local.new
    when "mux" then Providers::Mux.new
    when "bunny" then Providers::Bunny.new
    else raise UnknownProvider, "VIDEO_PROVIDER=#{name} is not one of: local, mux, bunny"
    end
  end
end
