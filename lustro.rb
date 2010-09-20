#!/usr/bin/ruby -wKU

module Lustro
  PublicMethods  = lambda { |cls| cls.public_instance_methods(false).sort }
  PrivateMethods = lambda { |cls| cls.private_instance_methods(false).sort }
  AllMethods     = lambda { |cls|
    (cls.public_instance_methods(false) +
      cls.private_instance_methods(false)).uniq.sort
  }

  def self.formatter
    @formatter ||= ColorFormatter.new
  end

  def self.formatter=(new_formatter)
    @formatter = new_formatter
  end

  def self.methods_for_class(cls,  getter=PublicMethods)
    cls.ancestors.map { |ruby_class|
      [ruby_class, normalize(getter[ruby_class])]
    }
  end

  def self.methods_for_object(obj, getter=PublicMethods)
    result = methods_for_class(obj.class, getter)
    left_overs = obj.methods - obj.class.public_instance_methods
    result.unshift([:singleton, normalize(left_overs)]) unless left_overs.empty?
    result
  end

  def self.format_help
    puts "Usage: m obj[, options]"
    puts
    puts "Options:"
    puts "  <int>                 -- Include only the first <int> ancestors."
    puts "  <-int>                -- Omit the last <int> ancestors."
    puts "  /re/                  -- Include only methods matching re."
    puts "  <class>               -- Include only methods from class."
    puts "  :deep                 -- Include Object and its ancestors."
    puts "  :omit, <class> (:o)   -- Exclude <class> and its ancestors."
    puts "  :instance      (:i)   -- Instance methods when obj is a class."
    puts "  :class         (:c)   -- Class methods from an instance."
    puts "  :public        (:pub) -- Public methods only (default)."
    puts "  :private       (:p)   -- Private methods only."
    puts "  :all                  -- Public and private methods."
    puts "  :ancestors     (:a)   -- Display Ancestors."
    puts "  :singleton     (:s)   -- Include only singleton methods."
    puts "  :flat          (:f)   -- Flatten the display into a single list of methods."
    puts "  :full                 -- List all ancestors, even if method list is empty."
    puts "  :noalpha       (:na)  -- Disable alphabetic bin sorting."
    puts "  :nocolor       (:nc)  -- Display without color."
  end

  def self.format(*args)
    if args.empty?
      format_help
      return
    end
    obj = args.shift
    fmt = formatter

    format_opts = {}
    methods = methods_for_object(obj)
    args << :omit << Object unless args.any? { |arg|
      arg.is_a?(Integer) ||
      arg.is_a?(Module) ||
      arg == :singleton || arg == :s ||
      arg == :deep || arg == :d
    }
    args.each do |arg|
      if format_opts[:omit] == :omit
        fail "'#{arg}' should be a class" unless arg.is_a?(Class)
        format_opts[:omit] = arg
        next
      end

      case arg
      when Regexp
        methods = filter(methods, arg)
      when Integer
        if arg < 0
          methods = methods[0 .. arg-1]
        elsif arg > 0
          methods = methods[0,arg]
        else
          # do nothing
        end
      when Module, Class
        methods = [methods.assoc(arg) || ["<#{arg} not found>", []]]
      when :deep, :d
        # do nothing
      when :singleton, :s
        methods = [methods.assoc(:singleton) || ["<:singleton not found>", []]]
      when :instance, :i
        fail ":instance requires a class object" unless obj.is_a?(Module)
        methods = methods_for_class(obj)
      when :class, :c
        methods = methods_for_object(obj.class)
      when :full
        format_opts[:full] = true
      when :private, :priv, :p
        methods = methods_for_object(obj, PrivateMethods)
        if methods.first.first == :singleton
          methods.shift
        end
        format_opts[:label] = "private"
      when :public, :pub
        methods = methods_for_object(obj, PublicMethods)
      when :all
        methods = methods_for_object(obj, AllMethods)
        format_opts[:label] = "all"
      when :omit, :o
        format_opts[:omit] = :omit
      when :flat, :f
        format_opts[:flat] = true
      when :noalpha, :na
        format_opts[:noalpha] = true
      when :nocolor, :nc
        fmt = Formatter.new
      when :ancestors, :a
        fmt.display_method_list(obj.class.ancestors)
        return
      else
        puts "Unrecognized option: #{arg.inspect}"
        return
      end
    end
    fmt.display(methods, format_opts)
    nil
  end

  def self.filter(methods, re)
    methods.map { |rc, ms|
      list = ms.grep(re)
      [rc, list]
    }
  end

  def self.normalize(list)
    list.map { |it| it.to_s }.sort
  end

  class Formatter
    attr_reader :options

    def emit(string)
      puts string
    end

    def display(methods, opts)
      @options = opts
      if options[:flat]
        list = methods.map { |rc, ms| ms }.flatten.sort
        the_class = methods.map { |m| m.first }.detect { |m| ! m.is_a?(Symbol) }
        display_scope(["#{the_class} (flat)", list])
      else
        methods.each do |scope|
          break if scope.first == options[:omit]
          display_scope(scope)
        end
      end
      @options = {}
    end

    def display_break
      emit
    end

    def display_class(ruby_class, method_list)
      string = ruby_class.to_s
      string << "/#{options[:label]}" if options[:label]
      string << " (#{method_list.size})"
      emit string
    end

    def display_scope(scope)
      ruby_class, method_list = scope
      if ! method_list.empty? || options[:full]
        display_class(ruby_class, method_list)
        display_methods(method_list)
        display_break
      end
    end

    def display_methods(methods)
      if options[:noalpha]
        display_method_list(methods)
      else
        categories = categorize_methods(methods)
        display_categories(categories)
      end
    end

    def display_categories(categories)
      categories.keys.sort.each do |k|
        display_method_list(categories[k])
      end
    end

    def display_method_list(method_list)
      emit "  #{method_list.join(' ')}"
    end

    def categorize_methods(methods)
      result = Hash.new { |h,k| h[k] = [] }
      methods.sort.each do |m|
        if m =~ /^[a-zA-Z]/
          result[m[0,1]] << m
        else
          result["@"] << m
        end
      end
      result
    end
  end

  module Color
    #shamelessly stolen (and modified) from redgreen
    COLORS = {
      :clear   => 0,  :black   => 30, :red   => 31,
      :green   => 32, :yellow  => 33, :blue  => 34,
      :magenta => 35, :cyan    => 36,
    }

    module_function

    COLORS.each do |color, value|
      module_eval "def #{color}(string); colorize(string, #{value}); end"
      module_function color
    end

    def colorize(string, color_value)
      if ENV['NO_COLOR']
        string
      else
        color(color_value) + string.to_s + color(COLORS[:clear])
      end
    end

    def color(color_value)
      "\e[#{color_value}m"
    end
  end

  class ColorFormatter < Formatter
    include Color

    def emit(str="")
      if @color
        puts @color[str]
      else
        puts str
      end
    end

    def c(color)
      @color = lambda { |s| send(color, s) }
      yield
    ensure
      @color = nil
    end

    def display_class(*args)
      c(:yellow) { super }
    end

    def display_method_list(*args)
      c(:cyan) { super }
    end
  end

  self.formatter = ColorFormatter.new
end

def m(*args)
  Lustro.format(*args)
  nil
end
