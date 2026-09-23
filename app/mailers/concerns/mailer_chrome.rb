module MailerChrome
  extend ActiveSupport::Concern

  MASCOT_ALIASES = {
    'dialogflow_disconnect' => 'dialog_flow_disconnect',
    'conversation_transcript' => 'conversion_transcript'
  }.freeze

  def self.mascot_slug(name)
    key = name.to_s
    MASCOT_ALIASES[key] || key
  end

  def self.mascot_public_path(name)
    slug = mascot_slug(name)
    relative = "email_icons/#{slug}.png"
    return "/#{relative}" if Rails.public_path.join(relative).exist?

    fallback = 'email_icons/base.png'
    return "/#{fallback}" if Rails.public_path.join(fallback).exist?

    nil
  end

  def self.blob_public_path
    relative = 'email_icons/gradient_blob.png'
    return "/#{relative}" if Rails.public_path.join(relative).exist?

    nil
  end

  CHROME = {
    'confirmation_instructions' => { icon: 'mail', heading: 'Confirm your email to get started', subtitle: 'Welcome' },
    'reset_password_instructions' => { icon: 'lock', heading: 'Reset your password', subtitle: 'Password reset' },
    'unlock_instructions' => { icon: 'unlock', heading: 'Unlock your account', subtitle: 'Account locked' },
    'password_change' => { icon: 'shield', heading: 'Your password was changed', subtitle: 'Security' },
    'conversation_creation' => { icon: 'chat', heading: 'New conversation', subtitle: 'A customer just reached out' },
    'conversation_assignment' => { icon: 'chat', heading: 'Conversation assigned', subtitle: 'This conversation is waiting on you' },
    'conversation_mention' => { icon: 'chat', heading: 'You were mentioned', subtitle: 'Someone tagged you in a conversation' },
    'assigned_conversation_new_message' => { icon: 'chat', heading: 'New message', subtitle: 'A customer replied in your assigned conversation' },
    'participating_conversation_new_message' => { icon: 'chat', heading: 'New message',
                                                  subtitle: 'There is a new reply in a conversation you follow' },
    'sla_missed_first_response' => { icon: 'alert', heading: 'First response SLA missed', subtitle: 'This conversation needs a reply now' },
    'sla_missed_next_response' => { icon: 'alert', heading: 'Next response SLA missed', subtitle: 'This conversation is past its reply target' },
    'sla_missed_resolution' => { icon: 'alert', heading: 'Resolution SLA missed', subtitle: 'This conversation is past its resolution target' },
    'email_disconnect' => { icon: 'alert', heading: 'Email inbox disconnected', subtitle: 'Reconnect it to keep receiving messages' },
    'whatsapp_disconnect' => { icon: 'alert', heading: 'WhatsApp inbox disconnected', subtitle: 'Reconnect it to keep receiving messages' },
    'instagram_disconnect' => { icon: 'alert', heading: 'Instagram inbox disconnected', subtitle: 'Reconnect it to keep receiving messages' },
    'facebook_disconnect' => { icon: 'alert', heading: 'Facebook inbox disconnected', subtitle: 'Reconnect it to keep receiving messages' },
    'slack_disconnect' => { icon: 'alert', heading: 'Slack disconnected', subtitle: 'Reconnect Slack to keep notifications flowing' },
    'openai_disconnect' => { icon: 'alert', heading: 'OpenAI disconnected', subtitle: 'Reconnect to keep Relay AI working' },
    'dialogflow_disconnect' => { icon: 'alert', heading: 'Dialogflow disconnected', subtitle: 'Reconnect to keep the bot running' },
    'payment_failure' => { icon: 'alert', heading: 'Payment failed', subtitle: 'A billing charge could not be completed' },
    'key_failure' => { icon: 'alert', heading: 'API key issue', subtitle: 'Relay AI could not use the configured key' },
    'attachment_failure' => { icon: 'alert', heading: 'Attachment failed', subtitle: 'A file could not be processed' },
    'automation_rule_disabled' => { icon: 'alert', heading: 'Automation disabled',
                                    subtitle: 'A rule was turned off because its conditions are invalid' },
    'contact_import_complete' => { icon: 'clipboard', heading: 'Contact import complete', subtitle: 'Your records are ready to review' },
    'contact_import_failed' => { icon: 'alert', heading: 'Contact import failed', subtitle: 'Some records could not be imported' },
    'contact_export_complete' => { icon: 'clipboard', heading: 'Contact export ready', subtitle: 'Your download is ready' },
    'account_deletion_user_initiated' => { icon: 'alert', heading: 'Account deletion scheduled',
                                           subtitle: 'Review this request before the deletion date' },
    'account_deletion_for_inactivity' => { icon: 'alert', heading: 'Account marked for deletion', subtitle: 'Sign in to keep this account active' },
    'account_deleted' => { icon: 'alert', heading: 'Account deleted', subtitle: 'This workspace has been removed' },
    'submitted' => { icon: 'clipboard', heading: 'Enterprise inquiry received', subtitle: 'Follow up from Super Admin when you are ready' },
    'send_link' => { icon: 'clipboard', heading: 'Complete your payment', subtitle: 'Activate your Enterprise plan' },
    'send_cname_instructions' => { icon: 'clipboard', heading: 'Connect your custom domain', subtitle: 'Add this DNS record to finish setup' },
    'message_created' => { icon: 'chat', heading: 'Automation triggered', subtitle: 'A message matched your automation' },
    'conversation_updated' => { icon: 'chat', heading: 'Conversation updated', subtitle: 'An automation ran on this conversation' }
  }.freeze

  private

  def email_chrome_icon
    @email_icon.presence || chrome_for_action[:icon]
  end

  def email_chrome_icon_url
    return if is_a?(ConversationReplyMailer)

    path = MailerChrome.mascot_public_path(action_name)
    absolute_asset_url(path) if path
  end

  def email_chrome_blob_url
    path = MailerChrome.blob_public_path
    absolute_asset_url(path) if path
  end

  def email_chrome_heading
    @email_heading.presence || chrome_for_action[:heading]
  end

  def email_chrome_subtitle
    @email_subtitle.presence || chrome_for_action[:subtitle]
  end

  def chrome_for_action
    CHROME[action_name.to_s] || {}
  end
end
