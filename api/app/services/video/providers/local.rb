# frozen_string_literal: true

module Video
  module Providers
    # Browser uploads straight to object storage with a presigned PUT; a Solid Queue job
    # then transcodes to an HLS ladder. Playback URLs are signed and short-lived, because a
    # paywalled lesson with a permanent video URL is one shared link away from being free.
    class Local
      LADDER = [
        { name: "360p", height: 360, bitrate: "800k" },
        { name: "720p", height: 720, bitrate: "2400k" },
        { name: "1080p", height: 1080, bitrate: "4800k" }
      ].freeze

      def direct_upload(video_asset)
        key = storage_key(video_asset, "source")
        {
          method: "PUT",
          url: Storage.presigned_put(key, expires_in: 30.minutes),
          key: key,
          headers: { "Content-Type" => "application/octet-stream" }
        }
      end

      def enqueue_processing(video_asset)
        Video::TranscodeJob.perform_later(video_asset.id)
      end

      def playback_url(video_asset, expires_in:)
        return nil unless video_asset.ready?

        Storage.presigned_get(storage_key(video_asset, "hls/master.m3u8"), expires_in: expires_in)
      end

      def storage_key(video_asset, suffix)
        "communities/#{video_asset.community_id}/videos/#{video_asset.id}/#{suffix}"
      end
    end
  end
end
