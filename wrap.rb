#07/08/10
# Make an object display another object's public interface - "favor composition
# over inheritance"

class Class

  # First attempt, doesn't work if wrapped objs change
  def wrap1(*classes)
    classes.each do |clsname|
      cls = eval clsname.to_s
      obj = cls.new
      @wrapped_objs ||= {}
      @wrapped_objs[clsname] = obj
      to_add = obj.methods.keep_if do |metname|
        m = obj.method metname
        m.owner == obj.class
      end
      to_add.each do |met|
        # This is the problem, if a wrapped obj is removed, how to
        # undefine this method? I kind of don't like 'undef'
        define_method met do |*params|
          obj.send met, *params
        end
      end
      define_method :initialize do
        self.class.wrapped_objs.each do |clsname, obj|
          instance_variable_set "@obj_#{clsname.downcase}", obj
        end
      end
    end
  end

  attr_reader :wrapped_classes

  def wrap(*classes)
    classes.each do |clsname|
      # is it safe to use eval here, in this way?
      cls = eval clsname.to_s
      obj = cls.new
      attr_reader :wrapped_objs
      @wrapped_classes ||= []
      @wrapped_classes.push clsname
      define_method :method_missing do |metname, *args|
        return_value = nil
        @wrapped_objs.each do |obj|
          begin
            return_value = obj.send metname, *args
          rescue NoMethodError => e
            next
          else
            break
          end
        end
        if return_value
          return_value
        else
          raise NoMethodError
        end
      end
      #FIXME for classes that define their own :initialize
      define_method :initialize do
        @wrapped_objs = self.class.wrapped_classes.collect do |clsname|
          #same here, safe to use eval?
          cls = eval clsname.to_s
          cls.new
        end
      end
    end
  end

  private :wrap
end



if __FILE__ == $0
  # testing

  class A
    def meta(a, b)
      "In meta: #{a} #{b}"
    end
  end

  class B
    wrap :A
  end

  class D
    def metd
      "In metd"
    end
  end

  class C
    wrap :B
    wrap :D
  end

  b = B.new

  p "b.meta 1,2 : #{b.meta 1, 2}"
  p "b.kind_of? A : #{b.kind_of? A}"
  p "b.wrapped_objs : #{b.wrapped_objs}"

  c = C.new

  p "c.meta 3,4 : #{c.meta 3,4}"
  p "c.metd : #{c.metd}"
  p "c.wrapped_objs : #{c.wrapped_objs}"
end
