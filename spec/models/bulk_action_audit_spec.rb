require 'rails_helper'

RSpec.describe BulkActionAudit do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:action_label) }
    it { is_expected.to validate_presence_of(:operation_type) }
  end

  describe 'status enum' do
    let(:audit) { create(:bulk_action_audit) }

    it 'defaults to pending' do
      expect(audit.status).to eq('pending')
    end

    it 'defines the expected statuses' do
      expect(described_class.statuses).to eq('pending' => 0, 'processing' => 1, 'completed' => 2, 'failed' => 3)
    end

    it 'transitions through the bulk action lifecycle' do
      audit.processing!
      expect(audit.reload.status).to eq('processing')

      audit.update!(status: :completed, completed_at: Time.zone.now, statistics: { total: 5, success: 5 })
      expect(audit.reload).to have_attributes(status: 'completed', completed_at: be_present)
    end

    it 'can transition to failed' do
      audit.failed!
      expect(audit.reload.status).to eq('failed')
    end
  end

  describe 'statistics' do
    it 'stores the total and success counts as a jsonb hash' do
      audit = create(:bulk_action_audit, statistics: { total: 10, success: 7 })
      expect(audit.reload.statistics).to eq('total' => 10, 'success' => 7)
    end
  end
end
