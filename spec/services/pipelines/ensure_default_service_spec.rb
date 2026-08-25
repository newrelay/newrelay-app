# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pipelines::EnsureDefaultService do
  describe '#perform' do
    it 'creates a default sales pipeline with stages' do
      account = create(:account)
      pipelines = described_class.new(account: account).perform

      expect(pipelines.count).to eq(1)
      expect(pipelines.first.name).to eq('Sales Pipeline')
      expect(pipelines.first.pipeline_stages.pluck(:name)).to eq(
        %w[Lead Qualified Proposal Negotiation Won Lost]
      )
    end

    it 'is idempotent' do
      account = create(:account)
      described_class.new(account: account).perform
      expect { described_class.new(account: account).perform }.not_to change(Pipeline, :count)
    end
  end
end
