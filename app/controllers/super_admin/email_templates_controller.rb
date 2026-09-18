class SuperAdmin::EmailTemplatesController < SuperAdmin::ApplicationController
  def index
    all_entries = EmailTemplates::Catalog.entries
    @categories = all_entries.map(&:category).uniq
    selected = params[:category].present? ? all_entries.select { |entry| entry.category == params[:category] } : all_entries
    @templates = decorate(selected)
  end

  def show
    load_template
  end

  def edit
    load_template
    return unless reject_unless_editable
  end

  def update
    load_template
    return unless reject_unless_editable

    record = installation_record
    record.body = template_params[:body]
    record.locale = :en if record.locale.blank?

    if record.save
      redirect_to super_admin_email_template_path(@entry.key), notice: I18n.t('super_admin.email_templates.updated')
    else
      @body = record.body
      flash.now[:error] = record.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    load_template
    installation_override&.destroy
    redirect_to super_admin_email_template_path(@entry.key), notice: I18n.t('super_admin.email_templates.reset_notice')
  end

  private

  def load_template
    @entry = EmailTemplates::Catalog.find!(params[:key])
    @override = installation_override
    @body = @override&.body.presence || @entry.file_body
  end

  def decorate(entries)
    overrides = EmailTemplate.where(account_id: nil, inbox_id: nil).index_by { |row| [row.name, row.template_type] }
    entries.map { |entry| [entry, overrides[[entry.name, entry.template_type]]] }
  end

  def installation_override
    EmailTemplate.find_by(name: @entry.name, template_type: @entry.template_type, account_id: nil, inbox_id: nil)
  end

  def installation_record
    EmailTemplate.find_or_initialize_by(name: @entry.name, template_type: @entry.template_type, account_id: nil, inbox_id: nil)
  end

  def reject_unless_editable
    return true if @entry.editable

    redirect_to super_admin_email_template_path(@entry.key), alert: I18n.t('super_admin.email_templates.not_editable')
    false
  end

  def template_params
    params.require(:email_template).permit(:body)
  end
end
