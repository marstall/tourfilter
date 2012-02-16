class TestClass
  @@a=nil
  
  def a=(val)
    @@a=val
  end
  
  def a
    @@a
  end
end

def eval(test)
  puts "a => #{test.a}"
end
  
test=TestClass.new
eval(test)
test.a=2
eval(test)
test2=TestClass.new
eval(test2)
test2.a=3
eval(test)
eval(test2)
