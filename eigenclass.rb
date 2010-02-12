class Object
  def eigenclass
    class << self; self; end
  end
end

class Class
  def metaclass
    eigenclass
  end
end
