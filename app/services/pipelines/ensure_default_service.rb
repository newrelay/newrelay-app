class Pipelines::EnsureDefaultService
  DEFAULT_STAGES = [
    { name: 'Lead', position: 0, color: 'primary' },
    { name: 'Qualified', position: 1, color: 'primary' },
    { name: 'Proposal', position: 2, color: 'warning' },
    { name: 'Negotiation', position: 3, color: 'primary' },
    { name: 'Won', position: 4, color: 'success', is_won: true },
    { name: 'Lost', position: 5, color: 'destructive', is_lost: true }
  ].freeze

  def initialize(account:)
    @account = account
  end

  def perform
    return @account.pipelines.includes(:pipeline_stages).order(:position) if @account.pipelines.exists?

    ActiveRecord::Base.transaction do
      pipeline = @account.pipelines.create!(name: 'Sales Pipeline', position: 0)
      DEFAULT_STAGES.each do |attrs|
        pipeline.pipeline_stages.create!(attrs.merge(account: @account))
      end
      @account.pipelines.includes(:pipeline_stages).order(:position)
    end
  end
end
