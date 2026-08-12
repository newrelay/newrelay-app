# Seeds enough open conversations so every conversation list tab has at least
# 10 rows: All, Mine, Unassigned, Mentions, and each Team.
#
# Usage:
#   Seeders::ConversationTabsSeeder.new(account: Account.find(1)).perform!
#   ACCOUNT_ID=1 bundle exec rake conversation_tabs:seed
class Seeders::ConversationTabsSeeder
  PER_TAB = 12

  pattr_initialize [:account!, :user]

  def perform!
    @user = user || account.administrators.first || account.users.first
    raise ArgumentError, "Account ##{account.id} has no users to seed for" if @user.blank?

    ensure_teams!
    ensure_inbox!
    ensure_inbox_memberships!
    ensure_team_memberships!

    mine = seed_assigned_conversations(count: PER_TAB, assignee: @user)
    unassigned = seed_assigned_conversations(count: PER_TAB, assignee: nil)
    team_conversations = seed_team_conversations
    mentioned = seed_mentions!(mine + unassigned + team_conversations)

    print_summary(mine, unassigned, team_conversations, mentioned)
  end

  private

  def ensure_teams!
    %w[Sales Support Success].each do |name|
      account.teams.find_or_create_by!(name: name) do |team|
        team.description = "#{name} team (seeded)"
        team.allow_auto_assign = true
      end
    end
  end

  def ensure_inbox!
    @inbox = account.inboxes.first
    return if @inbox.present?

    channel = Channel::WebWidget.create!(account: account, website_url: 'https://example.com')
    @inbox = account.inboxes.create!(name: 'Website', channel: channel)
  end

  def ensure_inbox_memberships!
    account.users.find_each do |member|
      InboxMember.find_or_create_by!(inbox: @inbox, user: member)
    end
  end

  def ensure_team_memberships!
    account.teams.find_each do |team|
      TeamMember.find_or_create_by!(team: team, user: @user)
    end
  end

  def seed_assigned_conversations(count:, assignee:)
    Array.new(count) do |index|
      create_open_conversation(
        assignee: assignee,
        label: assignee.present? ? 'mine' : 'unassigned',
        index: index
      )
    end
  end

  def seed_team_conversations
    conversations = []
    account.teams.find_each do |team|
      PER_TAB.times do |index|
        conversations << create_open_conversation(
          assignee: index.even? ? @user : nil,
          team: team,
          label: 'team',
          index: index
        )
      end
    end
    conversations
  end

  def seed_mentions!(conversations)
    conversations.first(PER_TAB).filter_map do |conversation|
      Mention.find_or_create_by!(user: @user, conversation: conversation, account: account) do |mention|
        mention.mentioned_at = Time.current
      end
    end
  end

  def create_open_conversation(assignee:, label:, index:, team: nil)
    contact = account.contacts.create!(
      name: "Seed #{label.titleize} Contact #{index + 1}",
      email: "seed-#{label}-#{SecureRandom.hex(4)}@example.com"
    )
    contact_inbox = ContactInbox.create!(
      contact: contact,
      inbox: @inbox,
      source_id: SecureRandom.uuid
    )
    conversation = Conversation.create!(
      account: account,
      inbox: @inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      assignee: assignee,
      team: team,
      status: :open
    )

    conversation.messages.create!(
      account: account,
      inbox: @inbox,
      message_type: :incoming,
      sender: contact,
      content: "Hello — seeded #{label} conversation ##{index + 1}"
    )
    if assignee.present?
      conversation.messages.create!(
        account: account,
        inbox: @inbox,
        message_type: :outgoing,
        sender: assignee,
        content: "Thanks for reaching out (#{label})."
      )
    end

    conversation
  end

  def print_summary(mine, unassigned, _team_conversations, mentioned)
    puts "Seeded conversation tabs for Account ##{account.id} (#{account.name})"
    puts "  Login user: #{@user.email}"
    puts "  Inbox: #{@inbox.name}"
    puts "  Teams: #{account.teams.pluck(:name).join(', ')}"
    puts "  All (open): #{account.conversations.open.count}"
    puts "  Mine: #{mine.size} (total assigned to user: #{account.conversations.open.where(assignee: @user).count})"
    puts "  Unassigned: #{unassigned.size} (total open unassigned: #{account.conversations.open.unassigned.count})"
    puts "  Mentions: #{mentioned.size} (total for user: #{Mention.where(user: @user, account: account).count})"
    account.teams.find_each do |team|
      puts "  Team '#{team.name}': #{account.conversations.open.where(team: team).count}"
    end
  end
end
