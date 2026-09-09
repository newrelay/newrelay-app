require 'rails_helper'

RSpec.describe MacrosExecutionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:macro) { create(:macro, account: account) }
  let(:conversation_1) { create(:conversation, account: account) }
  let(:conversation_2) { create(:conversation, account: account) }

  describe '#perform' do
    it 'executes the macro for every conversation in the batch' do
      conversation_ids = [conversation_1.display_id, conversation_2.display_id]

      expect(Macros::ExecutionService).to receive(:new).with(macro, conversation_1, user).and_call_original
      expect(Macros::ExecutionService).to receive(:new).with(macro, conversation_2, user).and_call_original

      described_class.perform_now(macro, conversation_ids: conversation_ids, user: user)
    end

    context 'when a conversation raises an error while executing' do
      it 'aborts the batch and does not process the remaining conversations' do
        conversation_ids = [conversation_1.display_id, conversation_2.display_id]

        service_for_first = instance_double(Macros::ExecutionService, perform: nil)
        allow(service_for_first).to receive(:perform).and_raise(StandardError.new('boom'))
        allow(Macros::ExecutionService).to receive(:new).with(macro, conversation_1, user).and_return(service_for_first)

        expect(Macros::ExecutionService).not_to receive(:new).with(macro, conversation_2, user)

        expect do
          described_class.perform_now(macro, conversation_ids: conversation_ids, user: user)
        end.to raise_error(StandardError, 'boom')
      end
    end
  end
end
