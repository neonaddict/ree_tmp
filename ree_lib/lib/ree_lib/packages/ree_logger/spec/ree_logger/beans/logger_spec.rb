# frozen_string_literal: true

package_require('ree_logger/beans/logger')

RSpec.describe :logger do
  link :is_blank, from: :ree_object
  link :logger, from: :ree_logger

  before(:all) do
    tmp_file_log = ENV['LOG_FILE_PATH']

    if !is_blank(tmp_file_log)
      File.open(tmp_file_log, 'w') {|file| file.truncate(0) }
    end
  end

  before(:each) do
    allow(Rollbar).to receive(:log)
    allow(Sentry).to receive(:capture_message)
  end

  let(:log_file_path) { ENV['LOG_FILE_PATH'] }

  let(:exception) {
    StandardError.new('Some Exception')
  }

  it {
    expect { logger.info('hello world') }.to output(/hello world/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("hello world")
  }

  it {
    expect { logger.info('hello world', { rollbar_scope: {fingerprint: 'test', test: 'test'}, param: 1, another_param: { name: 'John'} }) }.to output(/John/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("John")
  }

  it {
    expect { logger.debug('debug message') }.to_not output(/debug message/).to_stdout
    expect(Rollbar).not_to have_received(:log)
    expect(Sentry).not_to have_received(:capture_message)
    expect(File.read(log_file_path)).to_not match("debug")
  }

  it {
    expect { logger.warn('warning message') }.to output(/warning message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("warning message")
  }

  it {
    output = with_captured_stdout {
      logger.error('some error message', {}, exception, false)
    }
    expect(output).to match(/some error message/)
    expect(output).to_not match(/method|args/)
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("some error message")
    expect(File.read(log_file_path)).to_not match("PARAMETERS: {:method=>{:name=>:call, :args=>{:block=>{}}}}")
  }

  it {
    expect { logger.fatal('some fatal message', {}, exception) }.to output(/some fatal message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("some fatal message")
  }

  it {
    expect { logger.unknown('unknown message') }.to output(/unknown message/).to_stdout
    expect(Rollbar).to have_received(:log)
    expect(Sentry).to have_received(:capture_message)
    expect(File.read(log_file_path)).to match("unknown message")
  }
end
