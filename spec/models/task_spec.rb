# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task do
  let(:account) { create(:account) }

  it 'is invalid without a title' do
    task = described_class.new(account: account, title: nil)
    expect(task).not_to be_valid
  end

  it 'is valid with a title and account' do
    task = described_class.new(account: account, title: 'Follow up with customer')
    expect(task).to be_valid
  end
end
