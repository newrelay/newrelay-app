module Featurable
  extend ActiveSupport::Concern

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  FEATURE_LIST = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze

  # Only features up to index 63 can be stored in the bigint column due to 64-bit integer limits
  DB_FEATURES = FEATURE_LIST.first(63).each_with_object({}) do |feature, result|
    result[result.keys.size + 1] = "feature_#{feature['name']}".to_sym
  end

  VIRTUAL_FEATURES = FEATURE_LIST.drop(63).map { |f| f['name'] }.freeze

  module Overrides
    # Override selected_feature_flags to return both DB and Virtual features
    def selected_feature_flags
      flags = DB_FEATURES.values.select { |f| send("#{f}?") }
      flags += VIRTUAL_FEATURES.select { |f| send("feature_#{f}?") }.map { |f| "feature_#{f}".to_sym }
      flags
    end

    # Override selected_feature_flags= to assign both DB and Virtual features
    def selected_feature_flags=(features)
      features = Array(features).map(&:to_sym)

      # Update DB features
      DB_FEATURES.values.each do |f|
        send("#{f}=", features.include?(f))
      end

      # Update Virtual features
      self.settings ||= {}
      self.settings['virtual_features'] ||= {}
      VIRTUAL_FEATURES.each do |f|
        self.settings['virtual_features'][f.to_s] = features.include?("feature_#{f}".to_sym)
      end
    end
  end

  included do
    include FlagShihTzu
    has_flags DB_FEATURES.merge(column: 'feature_flags').merge(QUERY_MODE)

    prepend Overrides

    before_create :enable_default_features

    # Define dynamic getters/setters for virtual features
    VIRTUAL_FEATURES.each do |feature_name|
      define_method("feature_#{feature_name}?") do
        settings.dig('virtual_features', feature_name.to_s) || false
      end

      define_method("feature_#{feature_name}") do
        send("feature_#{feature_name}?")
      end

      define_method("feature_#{feature_name}=") do |val|
        self.settings ||= {}
        self.settings['virtual_features'] ||= {}
        self.settings['virtual_features'][feature_name.to_s] = ActiveModel::Type::Boolean.new.cast(val)
      end
    end
  end

  def enable_features(*names)
    names.each do |name|
      send("feature_#{name}=", true)
    end
  end

  def enable_features!(*names)
    enable_features(*names)
    save
  end

  def disable_features(*names)
    names.each do |name|
      send("feature_#{name}=", false)
    end
  end

  def disable_features!(*names)
    disable_features(*names)
    save
  end

  def feature_enabled?(name)
    send("feature_#{name}?")
  end

  def all_features
    FEATURE_LIST.pluck('name').index_with do |feature_name|
      feature_enabled?(feature_name)
    end
  end

  def enabled_features
    all_features.select { |_feature, enabled| enabled == true }
  end

  def disabled_features
    all_features.select { |_feature, enabled| enabled == false }
  end

  private

  def enable_default_features
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return true if config.blank?

    features_to_enabled = config.value.select { |f| f[:enabled] }.pluck(:name)
    enable_features(*features_to_enabled)
  end
end
