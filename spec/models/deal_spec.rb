# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deal do
  describe 'validations' do
    it 'requires name' do
      deal = build(:deal, name: nil)
      expect(deal).not_to be_valid
      expect(deal.errors[:name]).to be_present
    end

    it 'rejects stage from another pipeline' do
      account = create(:account)
      pipeline = create(:pipeline, :with_stages, account: account)
      other = create(:pipeline, :with_stages, account: account)
      deal = build(:deal, account: account, pipeline: pipeline, pipeline_stage: other.pipeline_stages.first)
      expect(deal).not_to be_valid
      expect(deal.errors[:pipeline_stage_id]).to be_present
    end
  end

  describe 'stage move' do
    it 'updates pipeline_stage' do
      deal = create(:deal)
      next_stage = deal.pipeline.pipeline_stages.second
      expect(deal.update(pipeline_stage: next_stage)).to be(true)
      expect(deal.reload.pipeline_stage_id).to eq(next_stage.id)
    end
  end
end
