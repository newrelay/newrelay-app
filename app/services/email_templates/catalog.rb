class EmailTemplates::Catalog
  Entry = Struct.new(
    :key,
    :name,
    :title,
    :category,
    :format,
    :template_type,
    :relative_path,
    :absolute_path,
    :editable,
    keyword_init: true
  ) do
    def file_body
      File.read(absolute_path)
    end
  end

  VIEWS_ROOT = Rails.root.join('app/views')
  SEARCH_DIRS = [
    ['mailers', 'content'],
    ['layouts/mailer', 'layout'],
    ['devise/mailer', 'content']
  ].freeze
  CATEGORY_PREFIXES = {
    'devise/' => 'Authentication',
    'layouts/' => 'Layout',
    'mailers/conversation_reply' => 'Conversation replies',
    'mailers/agent_notifications' => 'Agent notifications',
    'mailers/team_notifications' => 'Team notifications',
    'mailers/administrator_notifications' => 'Admin notifications',
    'mailers/reputation' => 'Reputation',
    'mailers/portal' => 'Help center'
  }.freeze

  def self.entries
    new.entries
  end

  def self.find(key)
    entries.find { |entry| entry.key == key }
  end

  def self.find!(key)
    find(key) || raise(ActiveRecord::RecordNotFound)
  end

  def entries
    SEARCH_DIRS.flat_map { |dir, type| scan(dir, type) }.sort_by { |entry| [entry.category, entry.title, entry.key] }
  end

  private

  def scan(dir, template_type)
    root = VIEWS_ROOT.join(dir)
    %w[liquid erb].flat_map { |ext| Dir.glob(root.join("**/*.#{ext}")) }.uniq.filter_map do |file|
      next if File.basename(file).start_with?('_')

      build_entry(Pathname.new(file), template_type)
    end
  end

  def build_entry(path, template_type)
    relative = path.relative_path_from(VIEWS_ROOT).to_s
    logical = strip_extension(relative)
    format = path.extname == '.liquid' ? 'liquid' : 'erb'
    basename = File.basename(logical)

    Entry.new(
      key: logical.gsub('/', '--'),
      name: basename.delete_prefix('_'),
      title: basename.delete_prefix('_').titleize,
      category: category_for(logical),
      format: format,
      template_type: template_type,
      relative_path: relative,
      absolute_path: path.to_s,
      editable: format == 'liquid' && !basename.start_with?('_')
    )
  end

  def strip_extension(relative)
    relative.delete_suffix('.html.erb').delete_suffix('.liquid').delete_suffix('.erb')
  end

  def category_for(logical)
    CATEGORY_PREFIXES.each { |prefix, label| return label if logical.start_with?(prefix) }
    'Other'
  end
end
