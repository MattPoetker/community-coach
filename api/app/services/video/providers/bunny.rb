# frozen_string_literal: true

module Video
  module Providers
    class Bunny
      def direct_upload(_video_asset)
        raise NotImplementedError, "Set BUNNY_LIBRARY_ID/BUNNY_API_KEY. See docs/VIDEO.md."
      end

      def enqueue_processing(_video_asset) = :handled_by_provider_webhook

      def playback_url(video_asset, expires_in:)
        return nil unless video_asset.ready?

        base = ENV.fetch("BUNNY_PULL_ZONE", "")
        expiry = expires_in.from_now.to_i
        "#{base}/#{video_asset.provider_ref}/playlist.m3u8?expires=#{expiry}"
      end
    end
  end
end
