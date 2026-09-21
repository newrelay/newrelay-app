# Allow audio attachments (call recordings, voice notes) to serve inline so the
# in-app <audio> player can stream them. Without this, ActiveStorage's blob model
# forces Content-Disposition: attachment for any MIME outside the default allowlist
# (images + PDF), which makes the browser download instead of play.
Rails.application.config.active_storage.content_types_allowed_inline += %w[
  audio/webm
  audio/ogg
  audio/mpeg
  audio/mp4
  audio/x-m4a
  audio/wav
  audio/x-wav
]

module ActiveStorageDirectUploadMetadataFilter
  INTERNAL_METADATA_KEYS = %w[identified analyzed composed].freeze

  private

  def blob_args
    super.tap do |args|
      args[:metadata]&.except!(*INTERNAL_METADATA_KEYS, *INTERNAL_METADATA_KEYS.map(&:to_sym))
    end
  end
end

module ActiveStorageFolderScopedKey
  # Cloudflare R2 (and any S3-compatible service) stores every object under a flat
  # key. Without this, every upload lands as a random key in the bucket root
  # instead of being namespaced by the record it belongs to.
  #
  # - Already-saved records (avatar, logo, ...) get "<records>/<id>/<field>/<token>",
  #   e.g. "users/42/avatar/<token>".
  # - Records built-and-attached in the same step (message attachments on channel
  #   webhooks, etc.) don't have an id yet, but usually already have account_id
  #   set (it's assigned before the attachment column in the same .new(...) call),
  #   so they get "accounts/<account_id>/<records>/<field>/<token>" instead.
  # - Anything with neither falls back to the default flat key.
  def find_or_build_blob
    blob = super
    return blob unless blob.new_record?

    key = folder_scoped_key
    blob.key = key if key
    blob
  end

  private

  def folder_scoped_key
    records = record.class.name.underscore.pluralize

    folder = if record.persisted?
               "#{records}/#{record.id}"
             elsif record.respond_to?(:account_id) && record.account_id.present?
               "accounts/#{record.account_id}/#{records}"
             end

    "#{folder}/#{name}/#{ActiveStorage::Blob.generate_unique_secure_token}" if folder
  end
end

module ActiveStorageProxyRangeLimit
  STREAMING_MAX_RANGES = 1
  STREAMING_CHUNK_MAX_SIZE = 100.megabytes

  private

  def send_blob_byte_range_data(blob, range_header, disposition: nil)
    ranges = Rack::Utils.get_byte_ranges(range_header, blob.byte_size)
    return head(:range_not_satisfiable) unless valid_ranges?(ranges)

    super
  end

  def valid_ranges?(ranges)
    ranges.present? &&
      ranges.any?(&:present?) &&
      ranges.length <= STREAMING_MAX_RANGES &&
      ranges.sum { |range| range.end - range.begin } < STREAMING_CHUNK_MAX_SIZE
  end
end

Rails.application.config.to_prepare do
  unless ActiveStorage::DirectUploadsController < ActiveStorageDirectUploadMetadataFilter
    ActiveStorage::DirectUploadsController.prepend(ActiveStorageDirectUploadMetadataFilter)
  end

  ActiveStorage::Streaming.prepend(ActiveStorageProxyRangeLimit) unless ActiveStorage::Streaming < ActiveStorageProxyRangeLimit

  unless ActiveStorage::Attached::Changes::CreateOne < ActiveStorageFolderScopedKey
    ActiveStorage::Attached::Changes::CreateOne.prepend(ActiveStorageFolderScopedKey)
  end
end
