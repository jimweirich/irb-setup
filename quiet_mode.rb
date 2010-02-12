#!/usr/bin/env ruby
# -*- ruby -*-

usage "--", "Print the last value"
def __
  p IRB.CurrentContext.last_value
  IRB.CurrentContext.echo ? nil : IRB.CurrentContext.last_value 
end

def set_echo_mode(is_echo)
  if IRB.CurrentContext && IRB.CurrentContext.respond_to?(:echo)
    IRB.CurrentContext.echo = is_echo
  else
    IRB.conf[:ECHO] = is_echo
  end
end

def quiet
  set_echo_mode(false)
end

def not_quiet
  set_echo_mode(true)
end  

usage "q", "Enter 'quiet' mode."
alias q quiet

usage "nq", "Exit 'quiet' mode."
alias nq not_quiet

not_quiet
