# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PipelineStage do
  let(:account) { create(:account) }
  let(:pipeline) { create(:pipeline, account: account) }

  it 'is invalid with a duplicate name in the same pipeline' do
    create(:pipeline_stage, account: account, pipeline: pipeline, name: 'Won')
    stage = build(:pipeline_stage, account: account, pipeline: pipeline, name: 'Won')

    expect(stage).not_to be_valid
    expect(stage.errors[:name]).to be_present
  end

  it 'is invalid when marked as both won and lost' do
    stage = build(:pipeline_stage, account: account, pipeline: pipeline, is_won: true, is_lost: true)

    expect(stage).not_to be_valid
    expect(stage.errors[:base]).to include('stage cannot be both won and lost')
  end
end
