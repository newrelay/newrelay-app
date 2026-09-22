class EmailTemplates::PreviewService
  SAMPLE_INNER_HTML = '<p>Hi Alex Rivera,</p><p>This is sample body content so you can see the layout around a message.</p>'.freeze
  DEVISE_PREVIEWS = {
    'confirmation_instructions' => ->(user) { Devise::Mailer.confirmation_instructions(user, 'preview-token') },
    'reset_password_instructions' => ->(user) { Devise::Mailer.reset_password_instructions(user, 'preview-token') },
    'unlock_instructions' => ->(user) { Devise::Mailer.unlock_instructions(user, 'preview-token') },
    'password_change' => ->(user) { Devise::Mailer.password_change(user) }
  }.freeze

  def initialize(entry:, body:)
    @entry = entry
    @body = body
  end

  def perform
    html = @entry.format == 'liquid' ? render_liquid_preview : render_erb
    return html if html.include?('<html')

    wrap_in_layout(html)
  rescue Liquid::Error, ActionView::Template::Error => e
    "<p>Could not render preview: #{ERB::Util.html_escape(e.message)}</p>"
  end

  private

  def render_liquid_preview
    return wrap_in_layout(SAMPLE_INNER_HTML, layout_html: @body) if layout?

    render_liquid(@body)
  end

  def render_liquid(source)
    Liquid::Template.parse(source).render(sample_assigns)
  end

  def wrap_in_layout(inner_html, layout_html: layout_source)
    render_liquid(layout_html.gsub('{{ content_for_layout }}', inner_html.to_s))
  end

  def layout?
    @entry.template_type == 'layout'
  end

  def layout_source
    layout_entry = EmailTemplates::Catalog.find('layouts--mailer--base')
    override = EmailTemplate.find_by(name: 'base', template_type: 'layout', account_id: nil, inbox_id: nil)
    override&.body.presence || layout_entry.file_body
  end

  def render_erb
    mail = devise_preview_mail
    return mail_html(mail) if mail.present?

    ActionController::Base.renderer.render(
      inline: @body,
      type: :erb,
      layout: false,
      assigns: erb_assigns,
      locals: erb_locals
    )
  end

  def devise_preview_mail
    builder = DEVISE_PREVIEWS[@entry.name]
    builder&.call(User.new(name: 'Alex Rivera', email: 'alex@example.com'))
  rescue StandardError
    nil
  end

  def mail_html(mail)
    mail.html_part&.decoded.presence || mail.body.decoded
  end

  def erb_assigns
    message = OpenStruct.new(
      content: 'Thanks for reaching out — we are looking into this.',
      outgoing_content: 'Thanks for reaching out — we are looking into this.',
      content_attributes: {}
    )
    { resource: User.new(name: 'Alex Rivera', email: 'alex@example.com'), token: 'preview-token', message: message,
      large_attachments: [] }
  end

  def erb_locals
    {
      action_text: 'Open conversation',
      action_url: brand_url,
      detail_rows: [],
      eyebrow: 'Preview',
      heading: 'Sample email heading',
      info_text: 'This is placeholder copy for the preview.',
      info_title: 'Preview notice',
      intro_text: 'This preview uses sample values in place of live mailer data.',
      recipient_name: 'Alex Rivera',
      supporting_text: 'Save an override, then open preview again to see template changes.'
    }
  end

  def sample_assigns
    {
      'user' => { 'available_name' => 'Alex Rivera', 'name' => 'Alex Rivera', 'email' => 'alex@example.com',
                  'first_name' => 'Alex', 'last_name' => 'Rivera', 'user_id' => 12, 'user_email' => 'alex@example.com' },
      'conversation' => sample_conversation,
      'inbox' => { 'name' => 'Website' },
      'account' => { 'name' => 'Acme' },
      'message' => { 'sender_display_name' => 'Jordan Lee', 'text_content' => 'Can someone look at this?' },
      'sla_policy' => { 'name' => 'First response in 15 minutes' },
      'action_url' => brand_url,
      'global_config' => { 'BRAND_NAME' => brand_name, 'BRAND_URL' => brand_url, 'LOGO' => brand_logo },
      'meta' => sample_meta,
      'account_name' => 'Acme',
      'monthly_price' => '199',
      'cname_record' => 'help.acme.test CNAME custom.example.com',
      'content_for_layout' => SAMPLE_INNER_HTML
    }
  end

  def sample_conversation
    {
      'display_id' => 42,
      'contact_name' => 'Jordan Lee',
      'recent_messages' => [
        { 'sender' => 'Jordan Lee', 'content' => 'Hi, I need help with my order.', 'attachments' => [] },
        { 'sender' => 'Alex Rivera', 'content' => 'Happy to help — could you share the order number?', 'attachments' => [] }
      ]
    }
  end

  def sample_meta
    {
      'account_name' => 'Acme', 'account_id' => 7, 'action' => 'Charge invoice', 'message' => 'Card was declined.',
      'error_message' => 'Card was declined.', 'payment_provider' => 'stripe', 'requested_by_name' => 'Alex Rivera',
      'requested_by_email' => 'alex@example.com', 'company_size' => '51-200', 'team_size' => '12',
      'desired_features' => ['SLA', 'Custom domain'], 'deletion_date' => 'October 1, 2026', 'instance_url' => brand_url,
      'marked_for_deletion_at' => 'October 1, 2026', 'deleted_at' => 'October 2, 2026',
      'deletion_reason' => 'Requested by administrator', 'deleted_user_count' => 1,
      'soft_deleted_users' => [{ 'user_id' => 12, 'user_email' => 'alex@example.com' }],
      'imported_contacts' => 48, 'failed_contacts' => 2, 'rule_name' => 'Assign new conversations'
    }
  end

  def brand_config
    @brand_config ||= GlobalConfig.get('BRAND_NAME', 'BRAND_URL', 'LOGO')
  end

  def brand_name
    brand_config['BRAND_NAME'].presence || 'newrelay'
  end

  def brand_url
    brand_config['BRAND_URL'].presence || 'https://app.example.com'
  end

  def brand_logo
    brand_config['LOGO'].presence || '/brand-assets/logo.svg'
  end
end
