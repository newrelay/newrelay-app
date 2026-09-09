# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pipeline do
  let(:account) { create(:account) }

  it 'is invalid without a name' do
    pipeline = build(:pipeline, account: account, name: nil)
    expect(pipeline).not_to be_valid
  end

  it 'is invalid with a duplicate name in the same account' do
    create(:pipeline, account: account, name: 'Sales Pipeline')
    pipeline = build(:pipeline, account: account, name: 'Sales Pipeline')

    expect(pipeline).not_to be_valid
    expect(pipeline.errors[:name]).to be_present
  end

  it 'is invalid with a negative position' do
    pipeline = build(:pipeline, account: account, position: -1)
    expect(pipeline).not_to be_valid
  end
end
