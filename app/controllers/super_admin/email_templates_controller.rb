class SuperAdmin::EmailTemplatesController < SuperAdmin::ApplicationController
  helper_method :email_template_scope, :custom_brand?, :audience_path

  before_action :load_template, except: :index

  def index
    all_entries = EmailTemplates::Catalog.entries
    @categories = all_entries.map(&:category).uniq
    selected = params[:category].present? ? all_entries.select { |entry| entry.category == params[:category] } : all_entries
    @templates = decorate(selected)
  end

  def show; end

  def preview
    @html = EmailTemplates::PreviewService.new(entry: @entry, body: @body, custom_brand: custom_brand?).perform
  end

  def edit
    return unless reject_unless_editable
  end

  def update
    return unless reject_unless_editable

    record = scoped_record
    record.body = template_params[:body]
    record.locale = :en if record.locale.blank?

    if record.save
      redirect_to super_admin_email_template_path(@entry.key, email_template_scope),
                  notice: I18n.t(notice_key('updated'))
    else
      @body = record.body
      flash.now[:error] = record.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    scoped_override&.destroy
    redirect_to super_admin_email_template_path(@entry.key, email_template_scope),
                notice: I18n.t(notice_key('reset_notice'))
  end

  private

  def load_template
    @entry = EmailTemplates::Catalog.find!(params[:key])
    @installation_override = shared_template(white_label: false)
    @override = shared_template(white_label: custom_brand?)
    @body = @override&.body.presence || (custom_brand? ? @installation_override&.body.presence : nil) || @entry.file_body
  end

  def decorate(entries)
    overrides = EmailTemplate.where(account_id: nil, inbox_id: nil, white_label: custom_brand?)
                             .index_by { |row| [row.name, row.template_type] }
    entries.map { |entry| [entry, overrides[[entry.name, entry.template_type]]] }
  end

  def shared_template(white_label:)
    EmailTemplate.find_by(
      name: @entry.name,
      template_type: @entry.template_type,
      account_id: nil,
      inbox_id: nil,
      white_label: white_label
    )
  end

  def scoped_override
    shared_template(white_label: custom_brand?)
  end

  def scoped_record
    EmailTemplate.find_or_initialize_by(
      name: @entry.name,
      template_type: @entry.template_type,
      account_id: nil,
      inbox_id: nil,
      white_label: custom_brand?
    )
  end

  def custom_brand?
    params[:audience] == 'custom_brand'
  end

  def email_template_scope
    custom_brand? ? { audience: 'custom_brand' } : {}
  end

  def audience_path(custom_brand)
    query = request.query_parameters.except('audience', 'account_id')
    query['audience'] = 'custom_brand' if custom_brand
    query.present? ? "#{request.path}?#{query.to_query}" : request.path
  end

  def notice_key(name)
    custom_brand? ? "super_admin.email_templates.#{name}_brand" : "super_admin.email_templates.#{name}"
  end

  def reject_unless_editable
    return true if @entry.editable

    redirect_to super_admin_email_template_path(@entry.key, email_template_scope),
                alert: I18n.t('super_admin.email_templates.not_editable')
    false
  end

  def template_params
    params.require(:email_template).permit(:body)
  end
end
