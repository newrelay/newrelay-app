namespace :contacts do
  desc 'Attach real profile image avatars to all contacts in the database'
  task seed_avatars: :environment do
    puts '📸 Attaching real profile picture avatars to contacts and users...'

    female_portraits = (1..95).map { |n| "https://randomuser.me/api/portraits/women/#{n}.jpg" }
    male_portraits   = (1..95).map { |n| "https://randomuser.me/api/portraits/men/#{n}.jpg" }

    contacts_count = 0
    users_count = 0

    Contact.find_each do |contact|
      # Reset rate-limiting attributes for avatar sync
      attrs = contact.additional_attributes || {}
      attrs.delete('last_avatar_sync_at')
      attrs.delete('avatar_url_hash')
      contact.update_columns(additional_attributes: attrs)

      # Deterministically pick portrait based on ID or contact email/name
      gender_female = contact.name.to_s.match?(/(jane|mary|sarah|linda|lorrie|tiffanie|melonie|viviene|coreen|merrile|elia|olia|elisabeth|ophelia|candice|karen|cathy|madge|glenn|louanne|stephanie)/i)
      portrait_list = gender_female ? female_portraits : male_portraits
      avatar_url = portrait_list[contact.id % portrait_list.size]

      begin
        Avatar::AvatarFromUrlJob.perform_now(contact, avatar_url)
        contacts_count += 1
        puts "  [Contact ##{contact.id}] Set avatar for #{contact.name.presence || contact.email} -> #{avatar_url}"
      rescue StandardError => e
        puts "  [Contact ##{contact.id}] Failed to set avatar: #{e.message}"
      end
    end

    User.find_each do |user|
      gender_female = user.name.to_s.match?(/(jane|mary|sarah|jo|karen|danny|cathy|stephanie|lonny|madge|glenn|louanne)/i)
      portrait_list = gender_female ? female_portraits : male_portraits
      avatar_url = portrait_list[user.id % portrait_list.size]

      begin
        Avatar::AvatarFromUrlJob.perform_now(user, avatar_url)
        users_count += 1
        puts "  [User ##{user.id}] Set avatar for #{user.name} -> #{avatar_url}"
      rescue StandardError => e
        puts "  [User ##{user.id}] Failed to set avatar: #{e.message}"
      end
    end

    puts "✨ Finished attaching avatars! Updated #{contacts_count} contact(s) and #{users_count} user(s)."
  end
end
