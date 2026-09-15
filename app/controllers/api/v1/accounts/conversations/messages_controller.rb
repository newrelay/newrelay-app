class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def search
    render json: { payload: { ids: search_message_ids } }
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
  rescue StandardError => e
    log_attachment_upload_failure(e) if params[:attachments].present?
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  private

  UPLOAD_NOTIFICATION_THROTTLE = 15.minutes

  def log_attachment_upload_failure(error)
    log = UploadActivityLog.create!(
      account: @conversation.account,
      user: Current.user,
      action: 'message_attachment_upload',
      status: 'failed',
      error_class: error.class.name,
      message: error.message.to_s.truncate(2000)
    )
    notify_super_admins_of_upload_failure(log)
  rescue StandardError => e
    Rails.logger.error("[UploadActivityLog] failed to record failure: #{e.class}: #{e.message}")
  end

  def notify_super_admins_of_upload_failure(log)
    return if UploadActivityLog.where.not(notified_at: nil).where(notified_at: UPLOAD_NOTIFICATION_THROTTLE.ago..).exists?

    log.update!(notified_at: Time.current)
    AdministratorNotifications::UploadAlertMailer.attachment_failure(
      action: log.action,
      message: log.message,
      account: log.account
    ).deliver_later
  rescue StandardError => e
    Rails.logger.error("[UploadAlertMailer] failed to queue notification: #{e.class}: #{e.message}")
  end

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def search_message_ids
    query = params[:q].to_s.strip
    return [] if query.length < 2

    escaped = ActiveRecord::Base.sanitize_sql_like(query)
    # ponytail: 200-match cap; page or raise the limit if agents need full-history find
    @conversation.messages
                 .where('content ILIKE :q OR processed_message_content ILIKE :q', q: "%#{escaped}%")
                 .order(created_at: :desc)
                 .limit(200)
                 .pluck(:id)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end
