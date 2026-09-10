# frozen_string_literal: true

module Video
  module Providers
    # Mux adapter. Present in v1 to prove the interface is real rather than aspirational —
    # a second implementation is the only way to know the first one was an abstraction.
    class Mux
      def direct_upload(video_asset)
        raise NotImplementedError, "Set MUX_TOKEN_ID/MUX_TOKEN_SECRET and implement the " \
                                   "direct-upload call. See docs/VIDEO.md."
      end

      def enqueue_processing(_video_asset) = :handled_by_provider_webhook

      def playback_url(video_asset, expires_in:)
        return nil unless video_asset.ready?

        "https://stream.mux.com/#{video_asset.provider_ref}.m3u8?token=#{signed_token(video_asset, expires_in)}"
      end

      private

      def signed_token(_asset, _expires_in)
        raise NotImplementedError, "Mux signed playback requires a signing key."
      end
    end
  end
end
