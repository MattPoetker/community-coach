# frozen_string_literal: true

module Video
  # ffmpeg to an HLS ladder. Concurrency is deliberately 1 in the shipped compose file:
  # transcoding will happily consume every core and starve the web process, and a member
  # waiting on a page load is a worse outcome than a lesson publishing a few minutes later.
  class TranscodeJob < ApplicationJob
    queue_as :media

    def perform(video_asset_id)
      asset = VideoAsset.unscoped.find(video_asset_id)
      with_community(asset.community_id) do
        asset.update!(status: "processing")
        renditions = transcode(asset)
        asset.update!(status: "ready", renditions: renditions)
      end
    rescue StandardError => e
      VideoAsset.unscoped.where(id: video_asset_id)
                .update_all(status: "failed", error_message: "#{e.class}: #{e.message}")
      raise
    end

    private

    def transcode(asset)
      provider = Video::Providers::Local.new
      source = download(provider.storage_key(asset, "source"))

      Video::Providers::Local::LADDER.map do |step|
        output = Rails.root.join("tmp", "#{asset.id}-#{step[:name]}.m3u8")
        run_ffmpeg(source, output, step)
        upload(output, provider.storage_key(asset, "hls/#{step[:name]}.m3u8"))
        { name: step[:name], height: step[:height] }
      end
    ensure
      FileUtils.rm_f(source) if source
    end

    def run_ffmpeg(source, output, step)
      command = [
        "ffmpeg", "-nostdin", "-y", "-i", source.to_s,
        "-vf", "scale=-2:#{step[:height]}",
        "-c:v", "h264", "-b:v", step[:bitrate], "-c:a", "aac", "-b:a", "128k",
        "-hls_time", "6", "-hls_playlist_type", "vod",
        output.to_s
      ]
      # Arguments are passed as an array, never a shell string — a filename is
      # user-supplied and would otherwise be a command-injection surface.
      raise "ffmpeg failed" unless system(*command, out: File::NULL, err: File::NULL)
    end

    def download(key)
      path = Rails.root.join("tmp", File.basename(key))
      File.binwrite(path, Storage.client.get_object(bucket: Storage.bucket, key: key).body.read)
      path
    end

    def upload(path, key)
      Storage.client.put_object(bucket: Storage.bucket, key: key, body: File.read(path))
    end
  end
end
