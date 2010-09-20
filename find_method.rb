#!/usr/bin/env ruby
# -*- ruby -*-

unless Object.const_defined?("BASE_METHODS")
  Object.const_set("BASE_METHODS", Object.new.methods)
end

def find_method(method_name)
  result = []
  method_name = Regexp.new(Regexp.quote(method_name.to_s)) if method_name.kind_of?(Symbol)
  method_name = Regexp.new(method_name) if method_name.kind_of?(String)
  ObjectSpace.each_object(Class) do |klass|
    methods = klass.instance_methods(false).select { |name| name =~ method_name }
    methods.each do |name|
      result << "#{klass}##{name}"
    end
  end
  puts result.sort
end

usage "fm", "Find method named NAME."
alias :fm :find_method
