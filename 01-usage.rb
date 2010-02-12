#!/usr/bin/env ruby
# -*- ruby -*-

unless Object.const_defined?("HELP")
  Object.const_set("HELP", [])
end

def usage(method_name=nil, comment=nil)
  if method_name.nil?
    width = HELP.collect { |pair| pair[0].size }.max
    HELP.sort.each do |name, desc|
      printf "%-#{width}s -- %s\n", name, desc
    end
  elsif comment.nil?
    puts "Usage: usage 'method_name', 'comment'"
  else
    HELP << [method_name, comment]
  end
  nil
end

usage "h", "Display help"
alias h usage

