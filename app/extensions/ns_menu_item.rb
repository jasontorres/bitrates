class NSMenuItem
  attr_accessor :key

  def checked
    self.state == NSOnState
  end

  def checked=(value)
    self.state = (value ? NSOnState : NSOffState)
  end
end
