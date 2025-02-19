# frozen_string_literal: true

class ReeLogger::Config
  include Ree::BeanDSL

  bean :config do
    singleton
    factory :build

    link :to_obj, from: :ree_object
    link :is_blank, from: :ree_object
    link :validate_inclusion, from: :ree_validator
  end

  LEVELS = %w[warn info debug error fatal unknown].freeze
  RATE_LIMIT_INTERVAL = 60
  RATE_LIMIT_MAX_COUNT = 600

  def build
    is_rollbar_enabled = parse_bool_string(ENV['LOG_ROLLBAR_ENABLED'])
    is_sentry_enabled = parse_bool_string(ENV['LOG_SENTRY_ENABLED'])

    to_obj({
      file_path: ENV['LOG_FILE_PATH'],
      file_auto_flush: parse_bool_string(ENV['LOG_FILE_AUTO_FLUSH']),
      levels: {
        file: parse_level(ENV['LOG_LEVEL_FILE']),
        stdout: parse_level(ENV['LOG_LEVEL_STDOUT']),
        rollbar: is_rollbar_enabled ? parse_level(ENV['LOG_LEVEL_ROLLBAR']) : nil,
        sentry: is_sentry_enabled ? parse_level(ENV['LOG_LEVEL_SENTRY']) : nil,
      },
      rollbar: {
        enabled: is_rollbar_enabled,
        access_token: is_rollbar_enabled ? ENV.fetch('LOG_ROLLBAR_ACCESS_TOKEN') : nil,
        environment: is_rollbar_enabled ? ENV.fetch('LOG_ROLLBAR_ENVIRONMENT') : nil,
        branch: ENV['LOG_ROLLBAR_BRANCH'],
        host: ENV['LOG_ROLLBAR_HOST']
      },
      sentry: {
        enabled: is_sentry_enabled,
        dsn: is_sentry_enabled ? ENV.fetch('LOG_SENTRY_DSN') : nil,
        environment: is_sentry_enabled ? ENV.fetch('LOG_SENTRY_ENVIRONMENT') : nil,
      },
      rate_limit: {
        interval: get_int_value('LOG_RATE_LIMIT_INTERVAL', RATE_LIMIT_INTERVAL),
        max_count: get_int_value('LOG_RATE_LIMIT_MAX_COUNT', RATE_LIMIT_MAX_COUNT),
      },
      default_filter_words: %w[
        password token credential bearer authorization
      ]
    })
  end

  private

  def get_int_value(name, default)
    value = ENV[name]

    v = if value.to_s.strip.empty?
      default
    else
      Integer(value)
    end

    if v < 0
      raise ArgumentError, "ENV['#{name}'] should be > 0"
    end

    v
  end

  def parse_bool_string(bool)
    return false if is_blank(bool)
    return bool.to_s.downcase == "true"
  end

  def parse_level(level)
    return if is_blank(level)
    validate_inclusion(level, LEVELS)
    level.to_sym
  end
end
