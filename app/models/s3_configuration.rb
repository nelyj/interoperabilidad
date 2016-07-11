module S3Configuration
  def codegen_bucket
    S3::Service.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      use_ssl: true
    ).bucket(ENV['S3_CODEGEN_BUCKET'])
  end
end

module S3

  def self.region
    ENV['AWS_REGION'] || 'us-east-1'
  end
  if region != 'us-east-1'
    HOST = "s3-#{region}.amazonaws.com"
  end
end
