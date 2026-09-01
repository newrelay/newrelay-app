require 'rails_helper'

shared_examples_for 'avatarable' do
  let(:avatarable) { create(described_class.to_s.underscore) }

  it 'has avatar attachment defined' do
    expect(avatarable).to respond_to(:avatar)
    expect(avatarable.avatar).to respond_to(:attach)
  end

  it 'add avatar_url method' do
    expect(avatarable.respond_to?(:avatar_url)).to be true
  end

  describe '#avatar_url' do
    let(:avatarable) { create(described_class.to_s.underscore, :with_avatar) }

    after { Avatarable.reset_image_processing_available! }

    it 'uses the original blob when image processing is unavailable' do
      allow(Avatarable).to receive(:image_processing_available?).and_return(false)

      expect(avatarable.avatar_url).to include('/rails/active_storage/blobs/')
    end

    it 'uses a representation when image processing is available' do
      allow(Avatarable).to receive(:image_processing_available?).and_return(true)

      expect(avatarable.avatar_url).to include('/rails/active_storage/representations/')
    end
  end

  context 'when avatarable has an email attribute' do
    it 'enques job when email is changed on avatarable create' do
      avatarable = build(described_class.to_s.underscore, account: create(:account))
      if avatarable.respond_to?(:email)
        avatarable.email = 'test@test.com'
        avatarable.skip_reconfirmation! if avatarable.is_a? User
        expect(Avatar::AvatarFromGravatarJob).to receive(:set).with(wait: 30.seconds).and_call_original
      end
      avatarable.save!
      expect(Avatar::AvatarFromGravatarJob).to have_been_enqueued.with(avatarable, avatarable.email) if avatarable.respond_to?(:email)
    end

    it 'enques job when email is changes on avatarable update' do
      if avatarable.respond_to?(:email)
        avatarable.email = 'xyc@test.com'
        avatarable.skip_reconfirmation! if avatarable.is_a? User
        expect(Avatar::AvatarFromGravatarJob).to receive(:set).with(wait: 30.seconds).and_call_original
      end
      avatarable.save!
      expect(Avatar::AvatarFromGravatarJob).to have_been_enqueued.with(avatarable, avatarable.email) if avatarable.respond_to?(:email)
    end

    it 'will not enqueu when email is not changed on avatarable update' do
      avatarable.updated_at = Time.now.utc
      expect do
        avatarable.save!
      end.not_to have_enqueued_job(Avatar::AvatarFromGravatarJob)
    end
  end
end
