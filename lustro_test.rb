require 'test/unit'
require 'shoulda'
require 'lustro'

class Parent
  def im_parent; end
  def self.cm_parent; end
end

class Sample < Parent
  def im_sample; end
  def self.cm_sample; end
end

class LustroTest < Test::Unit::TestCase
  def sample_object
    @sample_object ||= Sample.new
  end

  def methods
    @methdos ||= Lustro.methods_for(sample_object)
  end

  context "The methods_for" do

    context "a regular object" do
      should "contain the sample class methods" do
        assert_equal Sample, methods[0].first
        assert_equal ['im_sample'], methods[0][1]
      end

      should "containt the parent class methods" do
        assert_equal Parent, methods[1].first
        assert_equal ['im_parent'], methods[1][1]
      end

      should 'contain the object class methods' do
        assert_equal Object, methods[2].first
      end

      should 'contain the kernel module methods' do
        k_methods = methods.assoc(Kernel)
        assert_equal Kernel, k_methods.first
        assert_include "to_s", k_methods[1]
      end

      should "be sorted" do
        assert_sorted methods.assoc(Kernel)[1]
      end
    end

    context "an object with a singleton method" do
      should "have the singleton methods first" do
      end
    end
  end

  def assert_sorted(list)
    list.inject { |prev, item|
      assert prev < item, "#{prev} does not preceed #{item}"
      item
    }
  end

  def assert_include(expected, list)
    assert list.include?(expected), "<#{expected.inspect}> not included in\n<#{list.inspect}>"
  end
end
