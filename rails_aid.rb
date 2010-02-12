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
    
