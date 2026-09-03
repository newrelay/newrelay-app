class CommentAutomation::MockAutoresponderStore # rubocop:disable Metrics/ClassLength
  class Error < StandardError; end

  class << self
    def cache
      @cache ||= {}
    end

    def reset!
      cache.clear
    end
  end

  TEAM_MEMBERS = [
    { id: 'u-1', name: 'John Smith', email: 'john@example.com', avatar: 'https://i.pravatar.cc/150?u=john' },
    { id: 'u-2', name: 'Sarah Miller', email: 'sarah@example.com', avatar: 'https://i.pravatar.cc/150?u=sarah' },
    { id: 'u-3', name: 'Elena Rostova', email: 'elena@example.com', avatar: 'https://i.pravatar.cc/150?u=elena' },
    { id: 'u-4', name: 'David Vance', email: 'david@example.com', avatar: 'https://i.pravatar.cc/150?u=david' },
    { id: 'u-5', name: 'Michael Chang', email: 'michael@example.com', avatar: 'https://i.pravatar.cc/150?u=michael' },
    { id: 'u-6', name: 'Aisha Robinson', email: 'aisha@example.com', avatar: 'https://i.pravatar.cc/150?u=aisha' }
  ].freeze

  TEAMS = ['Sales Team', 'Support Team', 'Marketing Team', 'E-commerce Team', 'Customer Care'].freeze

  AUTOMATIONS = [
    'Summer Sale Comment Auto-DM',
    'Lead Qualification Bot',
    'Giveaway Entry Validator',
    'Product Inquiries Autoresponder',
    'Relay AI Smart Concierge',
    'Story Mention Acknowledgement'
  ].freeze

  SOCIAL_ACCOUNTS = [
    {
      id: 'acc-1', name: 'Main', handle: '@newrelay', platform: 'Instagram',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      status: 'Connected', automationsCount: 4, followersCount: '12,482 Followers',
      assignedTeam: 'Sales Team', accessLevel: 'Manager', lastSync: 'Just now',
      assignedMembers: [
        { id: 'u-1', name: 'John Smith', email: 'john@example.com', avatar: 'https://i.pravatar.cc/150?u=john', role: 'Manager' },
        { id: 'u-2', name: 'Sarah Miller', email: 'sarah@example.com', avatar: 'https://i.pravatar.cc/150?u=sarah', role: 'Operator' }
      ]
    },
    {
      id: 'acc-2', name: 'Support', handle: '@newrelay.support', platform: 'Instagram',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      status: 'Connected', automationsCount: 7, followersCount: '5,821 Followers',
      assignedTeam: 'Support Team', accessLevel: 'Manager', lastSync: '5 mins ago',
      assignedMembers: [
        { id: 'u-3', name: 'Elena Rostova', email: 'elena@example.com', avatar: 'https://i.pravatar.cc/150?u=elena', role: 'Manager' }
      ]
    },
    {
      id: 'acc-3', name: 'Store', handle: '@newrelay.store', platform: 'Instagram',
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      status: 'Connected', automationsCount: 3, followersCount: '8,150 Followers',
      assignedTeam: 'E-commerce Team', accessLevel: 'Operator', lastSync: '12 mins ago',
      assignedMembers: [
        { id: 'u-5', name: 'Michael Chang', email: 'michael@example.com', avatar: 'https://i.pravatar.cc/150?u=michael', role: 'Operator' }
      ]
    },
    {
      id: 'acc-4', name: 'Official Page', handle: 'fb.com/newrelay-official', platform: 'Facebook',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      status: 'Connected', automationsCount: 5, followersCount: '24,300 Likes',
      assignedTeam: 'Marketing Team', accessLevel: 'Manager', lastSync: '1 hour ago',
      assignedMembers: [
        { id: 'u-1', name: 'John Smith', email: 'john@example.com', avatar: 'https://i.pravatar.cc/150?u=john', role: 'Manager' }
      ]
    }
  ].freeze

  POSTS = [
    {
      id: 1, title: 'Summer Sale 2026 - Up to 40% Off', type: 'Post', publishedAt: 'Aug 28, 2026',
      thumbnail: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&auto=format&fit=crop&q=80',
      comments: { enabled: true, overridden: false, automation: 'Summer Sale Comment Auto-DM' },
      dms: { enabled: true, overridden: false, automation: 'Lead Qualification Bot' },
      stats: { commentsSent: 342, dmsSent: 289 }
    },
    {
      id: 2, title: 'Product Launch: NextGen Smartwatch Pro', type: 'Reel', publishedAt: 'Aug 25, 2026',
      thumbnail: 'https://images.unsplash.com/photo-1508057198894-247b23fe5ade?w=300&auto=format&fit=crop&q=80',
      comments: { enabled: false, overridden: true, automation: 'General Comment Acknowledgement' },
      dms: { enabled: true, overridden: false, automation: 'Product Inquiries Autoresponder' },
      stats: { commentsSent: 0, dmsSent: 412 }
    },
    {
      id: 3, title: 'Giveaway: Win AirPods Max & Store Credit', type: 'Carousel', publishedAt: 'Aug 20, 2026',
      thumbnail: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=300&auto=format&fit=crop&q=80',
      comments: { enabled: true, overridden: true, automation: 'Giveaway Entry Validator' },
      dms: { enabled: false, overridden: true, automation: 'Standard Welcome Flow' },
      stats: { commentsSent: 1240, dmsSent: 0 }
    },
    {
      id: 4, title: 'Behind The Scenes: How We Design Our Interfaces', type: 'Story', publishedAt: 'Aug 18, 2026',
      thumbnail: 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=300&auto=format&fit=crop&q=80',
      comments: { enabled: true, overridden: false, automation: 'Story Reply Capture' },
      dms: { enabled: true, overridden: false, automation: 'Story Mentions Auto-Reply' },
      stats: { commentsSent: 88, dmsSent: 120 }
    },
    {
      id: 5, title: 'Customer Spotlight: How BrandX Scaled 500%', type: 'Post', publishedAt: 'Aug 12, 2026',
      thumbnail: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=300&auto=format&fit=crop&q=80',
      comments: { enabled: true, overridden: false, automation: 'Case Study Request Reply' },
      dms: { enabled: true, overridden: false, automation: 'Enterprise Lead Route' },
      stats: { commentsSent: 215, dmsSent: 198 }
    }
  ].freeze

  DMS = [
    {
      id: 'general_dm', name: 'General Inbound DMs',
      description: 'Auto-reply to incoming customer questions in Direct Messages',
      enabled: true, overridden: false, automation: 'Relay AI Smart Concierge',
      stats: '1,420 replies sent this month'
    },
    {
      id: 'new_followers', name: 'New Follower Welcome DM',
      description: 'Send automated welcome message when a new user follows your profile',
      enabled: true, overridden: true, automation: 'New Follower Onboarding',
      stats: '680 DMs dispatched'
    },
    {
      id: 'story_mentions', name: 'Story Mentions & Tags',
      description: 'Instantly respond in DM when someone mentions your account in their Story',
      enabled: true, overridden: false, automation: 'Story Mention Acknowledgement',
      stats: '312 DMs dispatched'
    },
    {
      id: 'message_requests', name: 'Hidden / Message Requests Filter',
      description: 'Auto-screen and respond to pending message requests from non-followers',
      enabled: false, overridden: true, automation: 'Spam Prevention & Filter',
      stats: '0 replies (Paused)'
    }
  ].freeze

  def initialize(account)
    @account_id = account.id
  end

  def social_accounts
    data[:social_accounts]
  end

  def team_members
    mock? ? TEAM_MEMBERS.map(&:dup) : []
  end

  def teams
    mock? ? TEAMS.dup : []
  end

  def posts
    data[:posts]
  end

  def dms
    data[:dms]
  end

  def automations
    mock? ? AUTOMATIONS.dup : []
  end

  def defaults
    data[:defaults]
  end

  def update_social_account(id, attrs)
    account = social_accounts.find { |item| item[:id].to_s == id.to_s }
    return if account.blank?

    account.merge!(attrs.symbolize_keys.slice(:assignedTeam, :accessLevel, :assignedMembers, :lastSync))
    account
  end

  def connect(platform)
    raise Error, I18n.t('comment_automation.mock.disabled') unless mock?

    name = platform.to_s == 'Facebook' ? 'Facebook' : 'Instagram'
    next_id = "acc-#{social_accounts.length + 1}"
    account = {
      id: next_id, name: "New #{name}", handle: name == 'Facebook' ? "fb.com/new-#{next_id}" : "@new-#{next_id}",
      platform: name,
      avatar: "https://i.pravatar.cc/150?u=#{next_id}",
      status: 'Connected', automationsCount: 0, followersCount: name == 'Facebook' ? '0 Likes' : '0 Followers',
      assignedTeam: 'Sales Team', accessLevel: 'Manager', lastSync: 'Just now', assignedMembers: []
    }
    social_accounts << account
    account
  end

  def update_response_control(id, attrs) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    item = posts.find { |post| post[:id].to_s == id.to_s } || dms.find { |dm| dm[:id].to_s == id.to_s }
    return if item.blank?

    allowed = attrs.deep_symbolize_keys
    item[:comments] = item[:comments].merge(allowed[:comments]) if allowed[:comments] && item[:comments]
    item[:dms] = item[:dms].merge(allowed[:dms]) if allowed[:dms] && item[:dms]
    %i[enabled overridden automation].each { |key| item[key] = allowed[key] if allowed.key?(key) }
    item
  end

  def update_defaults(attrs)
    data[:defaults].merge!(attrs.symbolize_keys.slice(:comments, :dms))
    data[:defaults]
  end

  def sync
    social_accounts.each { |account| account[:lastSync] = 'Just now' }
    social_accounts
  end

  private

  def mock?
    CommentAutomation.mock?
  end

  def data
    return empty_data unless mock?

    self.class.cache[@account_id] ||= {
      social_accounts: SOCIAL_ACCOUNTS.deep_dup,
      posts: POSTS.deep_dup,
      dms: DMS.deep_dup,
      defaults: { comments: true, dms: true }
    }
  end

  def empty_data
    { social_accounts: [], posts: [], dms: [], defaults: { comments: true, dms: true } }
  end
end
