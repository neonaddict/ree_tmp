# frozen_string_literal: true

require_relative 'appender'
require 'digest'

class ReeLogger::SentryAppender < ReeLogger::Appender
  include Ree::LinkDSL

  link 'ree_logger/log_event', -> { LogEvent }

  contract(
    Symbol,
    Kwargs[
      dsn: String,
      environment: String,
    ] =>  Any
  )
  def initialize(level, dsn:, environment:)
    super(level, nil)

    require 'sentry-ruby'

    Sentry.init do |config|
      config.dsn = dsn
      config.max_breadcrumbs = 5
      config.environment = environment

      # Add data like request headers and IP for users, if applicable;
      # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
      config.send_default_pii = true

      # enable tracing
      # we recommend adjusting this value in production
      config.traces_sample_rate = 1.0
    end
  end

  contract(LogEvent, Nilor[String] => nil)
  def append(event, progname = nil)
    sentry_level =
      case event.level
      when :warn
        :warning
      when :unknown
        :error
      else
        event.level
      end

    fingerprint = event.message.to_s

    if event.exception
      fingerprint += event.exception.class.to_s
    end

    scope = {}
    parameters = event.parameters.dup

    if !scope[:fingerprint]
      fingerprint = event.message.to_s

      if event.exception
        fingerprint += event.exception.class.to_s
      end

      scope[:fingerprint] = Digest::MD5.new.update(fingerprint).to_s
    end


    Sentry.capture_message(event.message, level: sentry_level, exception: event.exception, params: parameters)

    nil
  end
end
