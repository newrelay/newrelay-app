class Api::V1::Accounts::TasksController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_tasks, only: [:index]
  before_action :fetch_task, only: [:show, :update, :destroy]

  def index
    render json: @tasks.as_json(include: { contacts: { only: [:id, :name, :email] } })
  end

  def show
    render json: @task.as_json(include: { contacts: { only: [:id, :name, :email] } })
  end

  def create
    @task = Current.account.tasks.new(permitted_payload.except(:contact_ids))
    if @task.save
      @task.contact_ids = permitted_payload[:contact_ids] if permitted_payload[:contact_ids].present?
      render json: @task.as_json(include: { contacts: { only: [:id, :name, :email] } }), status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(permitted_payload.except(:contact_ids))
      @task.contact_ids = permitted_payload[:contact_ids] if permitted_payload.key?(:contact_ids)
      render json: @task.as_json(include: { contacts: { only: [:id, :name, :email] } })
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    head :no_content
  end

  private

  def fetch_tasks
    @tasks = Current.account.tasks
    apply_completed_and_assignee_filters
    apply_due_filter if permitted_params[:due_filter].present?
    apply_search_query if permitted_params[:q].present?

    return if permitted_params[:contact_id].blank?

    @tasks = @tasks.joins(:contact_tasks).where(contact_tasks: { contact_id: permitted_params[:contact_id] })
  end

  def apply_completed_and_assignee_filters
    @tasks = @tasks.where(completed: ActiveModel::Type::Boolean.new.cast(permitted_params[:completed])) if permitted_params[:completed].present?
    @tasks = @tasks.where(assignee_id: permitted_params[:assignee_id]) if permitted_params[:assignee_id].present?
  end

  def apply_due_filter
    case permitted_params[:due_filter]
    when 'today'
      @tasks = @tasks.where(due_at: Time.zone.now.all_day)
    when 'overdue'
      @tasks = @tasks.where('due_at < ?', Time.zone.now).where(completed: [false, nil])
    when 'upcoming'
      @tasks = @tasks.where('due_at > ?', Time.zone.now)
    end
  end

  def apply_search_query
    query = "%#{permitted_params[:q]}%"
    @tasks = @tasks.where('title ILIKE ? OR description ILIKE ?', query, query)
  end

  def fetch_task
    @task = Current.account.tasks.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:task).permit(
      :title,
      :description,
      :completed,
      :due_at,
      :assignee_id,
      contact_ids: []
    )
  end

  def permitted_params
    params.permit(:id, :completed, :assignee_id, :contact_id, :due_filter, :q)
  end
end
