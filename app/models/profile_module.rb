module ProfileModule

  @debug=false
  def start_timer(name)
    @timers||= Hash.new
    @timers[name]=Time.new
  end
  
  def end_timer(name,output=true)
    raise unless @timers[name]
    delta = Time.new - @timers[name]
    ms = Integer(delta*1000)
    s = "=== #{name}: #{ms}ms"
    puts s if output and @debug
#    logger.info s if logger and output
    return ms
  end
end