class Exception
  def self.children
    @children ||= []
  end
end

def exceptions
  ObjectSpace.each_object(Class) do |klass|
    next if klass.to_s =~ /^(IRB|RubyLex|Errno)/
    next unless klass.ancestors.include?(Exception)
    begin
      klass.superclass.children << klass unless klass == Exception
    rescue NoMethodError => ex
      puts "For #{klass}: #{ex.message}"
    end
  end
  show_exceptions(Exception)
end

def show_exceptions(root, indent=0)
  puts "#{'  '*indent}#{root}"
  root.children.each do |child|
    show_exceptions(child, indent + 1)
  end
  nil
end
  
