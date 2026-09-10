# frozen_string_literal: true

# Thin wrapper over the S3-compatible bucket. MinIO in development and in the documented
# compose file; S3, R2 or Spaces in production — the API is identical, which is the point
# of insisting on S3 compatibility rather than a vendor SDK.
module Storage
  module_function

  def client
    @client ||= begin
      require "aws-sdk-s3"
      Aws::S3::Client.new(
        access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"),
        secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY"),
        region: ENV.fetch("S3_REGION", "us-east-1"),
        endpoint: ENV.fetch("S3_ENDPOINT", nil),
        force_path_style: ENV.fetch("S3_FORCE_PATH_STYLE", "true") == "true"
      )
    end
  end

  def bucket = ENV.fetch("S3_BUCKET", "community-coach")

  def presigned_put(key, expires_in:)
    presigner.presigned_url(:put_object, bucket: bucket, key: key, expires_in: expires_in.to_i)
  end

  def presigned_get(key, expires_in:)
    presigner.presigned_url(:get_object, bucket: bucket, key: key, expires_in: expires_in.to_i)
  end

  def presigner
    require "aws-sdk-s3"
    @presigner ||= Aws::S3::Presigner.new(client: client)
  end
end
