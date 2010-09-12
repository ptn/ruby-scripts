# 19/08/10

module Debug
  # Log to a file either a) the value of some variables at the point of
  # invocation or b) a message.
  #
  # The variables are passed inside a block as an array of symbols.
  def Debug.debug(opts={}, &blk)
    msg = []
    if opts.include? :msg
      msg << "#{opts[:msg]}"
    end
    if block_given?
      (yield.map &:to_s).each do |var|
        val = eval var, blk.binding
        msg << "#{var} = #{val}"
      end
    end
    unless msg.empty?
      msg.unshift caller.last.to_s
      log = opts[:log] || "debug.log"
      File.open log, "a" do |log|
        log.write msg.join("\n")
        log.write "\n\n"
      end
    end
  end
end

if __FILE__ == $0
  x = 1
  y = 2
  Debug.debug { [:x, :y] }
  z = 3
  Debug.debug { [:x, :y, :z] }
  Debug.debug msg: "Test"
  Debug.debug
  Debug.debug msg: "Test 2" do
    [:x, :y]
  end
end
