#30/01/10
# First attempt at metaprogramming.  I shouldn't have put those methods at the 
# top level, I should have opened up the Class class and write them there.  
# Anyway, this was 1 week after I had started learning Ruby.

def my_attr_reader(*args)
	args.each do |a|
		self.class_eval do
			instance_variable_set "@#{a}", nil
			define_method a do
				instance_variable_get "@#{a}"
			end
		end
	end
end

def my_attr_writer(*args)
	args.each do |a|
		self.class_eval do
			instance_variable_set "@#{a}", nil
			define_method "#{a}=" do |val|
				instance_variable_set "@#{a}", val
			end
		end
	end
end

def my_attr_accessor(*args)
	my_attr_reader *args
	my_attr_writer *args
end
