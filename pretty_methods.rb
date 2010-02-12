#!/usr/bin/env ruby
# -*- ruby -*-

unless Object.const_defined?("BASE_METHODS")
  Object.const_set("BASE_METHODS", Object.new.methods)
end

def find_method(method_name)
  result = []
#  method_name = Regexp.new(Regexp.quote(method_name.to_s)) if method_name.kind_of?(Symbol)
  method_name = Regexp.new(method_name) if method_name.kind_of?(String)
  ObjectSpace.each_object(Class) do |klass|
    methods = klass.instance_methods.select { |name| name =~ method_name }
    methods.each do |name|
      result << "#{klass}##{name}"
    end
  end
  puts result.sort
end

def pretty_list(list, all=:shallow)
  list = (list - BASE_METHODS) if all == :shallow
  list = list.select { |m| m.to_s =~ all } if all.kind_of?(Regexp)
  categories = Hash.new { |h, k| h[k] = [] }
  list.sort.each do |m|
    if m =~ /^[a-zA-Z]/
      categories[m[0,1]] << m
    else
      categories['@'] << m
    end
  end
  categories.keys.sort.each do |k|
    puts "    #{categories[k].join(' ')}"
  end
  nil
end

def pretty_methods(obj, all=false)
  methods = obj.methods
  case obj
  when Class
    methods -= Class.methods unless all 
  end
  pretty_list(obj.methods, all)
end

def pretty_class_methods(obj, all=false)
  case obj
  when Class
    pretty_list(obj.methods, all)
  else
    pretty_list(obj.class.methods, all)
  end
end

def pretty_instance_methods(klass, all=false)
  pretty_list(klass.instance_methods, all)
end

usage "m", "Pretty print all the methods of an object"
alias :m :pretty_methods

usage "cm", "Pretty print all the class methods of an object."
alias :cm :pretty_class_methods

usage "im", "Pretty print all the instance methods of a class object."
alias :im :pretty_instance_methods

usage "fm", "Find method named NAME."
alias :fm :find_method
