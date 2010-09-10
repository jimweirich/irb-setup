usage "factory", "load factory_girl and any factories"
def factory
  require 'factory_girl'
  require 'test/factories' if File.exist?('test/factories')
end

JW_RAILS_AID_ORIGINAL_LOGGER = []

module JW
  class Logger
    def initialize
      @to_console = false
      @rails_logger = nil
    end

    def use_console
      capture_rails_logger
      @to_console = true
      switching_logs
    end

    def use_rails
      capture_rails_logger
      @to_console = false
      switching_logs
    end

    def console_logger
      @console_logger ||= ::Logger.new($stdout)
    end

    def rails_logger
      @rails_logger
    end

    def warn(*args);  both(:warn,  *args);  end
    def debug(*args); both(:debug, *args); end
    def info(*args);  both(:info,  *args);  end
    def error(*args); both(:error, *args); end

    def method_missing(symbol, *args, &block)
      rails_logger.__send__(symbol, *args, &block)
    end

    def both(level, *args)
      console_logger.__send__(level, *args) if @to_console
      rails_logger.__send__(level, *args)
    end

    def capture_rails_logger
      if @rails_logger.nil?
        @rails_logger = ActiveRecord::Base.logger
        ActiveRecord::Base.logger = self
      end
    end

    def switching_logs
      ActiveRecord::Base.clear_active_connections!
    end
  end
end

JW_RAILS_LOGGER = JW::Logger.new

usage "log_to", "set the Rails logging stream"
def log_to(stream = $stderr)
  jw_capture_log
  case stream
  when IO
    puts "Logger stream"
    ActiveRecord::Base.logger = Logger.new(stream)
  else
    puts "Logger Logger"
    ActiveRecord::Base.logger = stream
  end
  ActiveRecord::Base.clear_active_connections!
  nil
end

usage "log_console", "Send logging output to the console"
def log_console
  JW_RAILS_LOGGER.use_console
  nil
end

usage "log_default", "Send logging output to the default Rails destination"
def log_default
  ActiveRecord::Base.logger = JW_RAILS_LOGGER
  JW_RAILS_LOGGER.use_rails
  nil
end

usage "session", "get the session object for a session id"
def session(session_id=nil)
  fail "Rails Session not loaded" unless
    defined? CGI::Session::ActiveRecordStore::Session

  if session_id
    @session_id = session_id
  else
    session_id = @session_id
  end
  fail "Need a Session ID" unless session_id
  session = CGI::Session::ActiveRecordStore::Session.find_by_session_id(session_id)
  eval %{
      def session.to_s
        "<Session@#{session_id}>"
      end
      def session.decode
        safe_marshal_load(self['data'].unpack('m').first)
      end
  }
  def session.inspect
    to_s
  end
  session
end

usage "safe_marshal_load", "Load the marshalled data safely"
def safe_marshal_load(marsh_data)
  missing_constants_seen = {}
  begin
    Marshal.load(marsh_data)
  rescue ArgumentError => ex
    if ex.message =~ /^undefined class\/module (.+)/
      class_name = $1
      logger.info("Marshalled class not found: #{class_name}, autoloading and trying again")
      unless missing_constants_seen[class_name]
        missing_constants_seen[class_name] = true
        class_name.constantize rescue nil
        retry
      end
    end
  end
end

class HistoryMonitor
  def initialize(session_id)
    @session_id = session_id
  end
  def show
    s = session(@session_id)
    s.decode[:history_stack].show
  end
end

def hm(id=nil)
  if id
    @monitor = HistoryMonitor.new(id)
  end
  if @monitor.nil?
    fail "Need session id"
  end
  @monitor.show
end

