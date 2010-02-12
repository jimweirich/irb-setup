#!/usr/bin/env ruby
# -*- ruby -*-

usage "clear", "Clear the Screen"
def clear
  system "clear"
end
alias :cls :clear

usage "noecho", "Do not echo characters as typed (for emacs shell mode)."
def noecho
  puts `stty -echo`
end

usage "echo", "Echo characters as typed."
def echo
  puts `stty echo`
end

def in_emacs_shell?
  ENV['TERM'] == 'dumb'
end

def emacs_noecho
  noecho if in_emacs_shell?
end

#emacs_noecho

END {
  emacs_noecho
}
