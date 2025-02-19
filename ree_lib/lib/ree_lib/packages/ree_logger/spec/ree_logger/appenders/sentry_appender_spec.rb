#frozen_string_literal: true

package_require('ree_logger/appenders/sentry_appender')

RSpec.describe ReeLogger::SentryAppender do
  let(:sentry_appender) { described_class }

  let(:log_event) {
    ReeLogger::LogEvent.new(
      :info,
      "Some message",
      nil,
      {}
    )
  }

  # comment "before" block to test sending to api
  before do
    allow(Sentry).to receive(:capture_message)
  end

  it "sends log event to Sentry" do
    appender = sentry_appender.new(
      :info,
      dsn: ENV['LOG_SENTRY_DSN'],
      environment: ENV['LOG_SENTRY_ENVIRONMENT']
    )

    expect(appender).to respond_to(:append)
    expect { appender.append(log_event) }.not_to raise_error
    expect(Sentry).to have_received(:capture_message)
  end
end
