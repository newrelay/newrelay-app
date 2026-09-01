require 'rails_helper'

RSpec.describe Instagram::MessageText do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_instagram, account: account, instagram_id: 'ig-account-1') }
  let(:inbox) { channel.inbox }
  let(:campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
  let(:trigger) { create(:comment_automation_trigger, campaign: campaign, account: account) }
  let(:service) { described_class.new({}, channel) }

  before do
    service.instance_variable_set(:@inbox, inbox)
    stub_request(:get, /graph\.instagram\.com/).to_return(
      status: 200,
      body: { id: 'commenter-1', name: 'Jane', username: 'jane_doe' }.to_json
    )
  end

  context 'when the commenter has a dm_sent comment automation log' do
    let!(:log) do
      create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                              comment_id: 'comment-1', commenter_id: 'commenter-1', status: :dm_sent)
    end

    it 'merges campaign attribution onto the new contact' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(contact.custom_attributes['comment_automation_campaign_id']).to eq campaign.id
      expect(contact.custom_attributes['comment_automation_trigger_id']).to eq trigger.id
    end

    it 'marks the message log engaged and links the new contact' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(log.reload.status).to eq 'engaged'
      expect(log.contact).to eq contact
    end

    context 'when the commenter has a second dm_sent log from a different campaign' do
      let(:other_campaign) { create(:comment_automation_campaign, account: account, inbox: inbox) }
      let(:other_trigger) { create(:comment_automation_trigger, campaign: other_campaign, account: account) }
      # Override `log` (the outer let!) so it is the newest dm_sent row, and make `other_log`
      # older, so the ordering is deterministic regardless of let! evaluation order.
      let!(:log) do
        create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                                comment_id: 'comment-1', commenter_id: 'commenter-1', status: :dm_sent,
                                                created_at: 1.minute.ago)
      end
      let!(:other_log) do
        create(:comment_automation_message_log, trigger: other_trigger, account: account, inbox: inbox,
                                                comment_id: 'comment-2', commenter_id: 'commenter-1', status: :dm_sent,
                                                created_at: 2.minutes.ago)
      end

      it 'keeps attribution pinned to whichever campaign engaged first across repeated inbound DMs' do
        service.ensure_contact('commenter-1')
        service.ensure_contact('commenter-1')

        contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
        expect(contact.custom_attributes['comment_automation_campaign_id']).to eq campaign.id
        expect(contact.custom_attributes['comment_automation_trigger_id']).to eq trigger.id
        expect(log.reload.status).to eq 'engaged'
        expect(other_log.reload.status).to eq 'dm_sent'
      end
    end
  end

  context 'when the commenter already has a contact_inbox' do
    # The returning-contact path: `ensure_contact` is skipped entirely because
    # `contacts_first_message?` is false, so attribution has to happen in `perform`.
    let!(:contact_inbox) { channel.create_contact_inbox('commenter-1', 'Jane') }
    let!(:log) do
      create(:comment_automation_message_log, trigger: trigger, account: account, inbox: inbox,
                                              comment_id: 'comment-1', commenter_id: 'commenter-1', status: :dm_sent)
    end
    let(:messaging) do
      { sender: { id: 'commenter-1' }, recipient: { id: 'ig-account-1' },
        timestamp: Time.current.to_i, message: { mid: 'mid-1', text: 'hey' } }.with_indifferent_access
    end

    it 'attributes the campaign and engages the log without creating the contact' do
      described_class.new(messaging, channel).perform

      expect(contact_inbox.contact.reload.custom_attributes).to include(
        'comment_automation_campaign_id' => campaign.id,
        'comment_automation_trigger_id' => trigger.id
      )
      expect(log.reload.status).to eq 'engaged'
      expect(log.contact).to eq contact_inbox.contact
    end
  end

  context 'when the commenter has no comment automation log' do
    it 'creates the contact without touching custom_attributes' do
      service.ensure_contact('commenter-1')

      contact = inbox.contact_inboxes.find_by(source_id: 'commenter-1').contact
      expect(contact.custom_attributes['comment_automation_campaign_id']).to be_nil
    end
  end
end
