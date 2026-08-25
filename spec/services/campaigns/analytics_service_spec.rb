# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Campaigns::AnalyticsService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe '#perform' do
    it 'returns summary counts and campaign rows with conversation attribution' do
      active = create(:campaign, account: account, inbox: inbox, campaign_status: :active)
      completed = create(:campaign, account: account, inbox: inbox, campaign_status: :completed)
      create(:conversation, account: account, inbox: inbox, campaign: active)
      create(:conversation, account: account, inbox: inbox, campaign: active)
      create(:conversation, account: account, inbox: inbox, campaign: completed)

      result = described_class.new(account: account).perform

      expect(result[:summary][:total_campaigns]).to eq(2)
      expect(result[:summary][:active]).to eq(1)
      expect(result[:summary][:completed]).to eq(1)
      expect(result[:summary][:attributed_conversations]).to eq(3)

      active_row = result[:campaigns].find { |row| row[:id] == active.id }
      expect(active_row[:conversations_count]).to eq(2)
    end

    it 'returns zeros when there are no campaigns' do
      result = described_class.new(account: account).perform

      expect(result[:summary][:total_campaigns]).to eq(0)
      expect(result[:summary][:attributed_conversations]).to eq(0)
      expect(result[:campaigns]).to eq([])
    end
  end
end
