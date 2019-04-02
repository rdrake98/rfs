# ruby_dom.rb

require 'ruby_dom'

class RubyDOMNull < RubyDOM
  def []= name, value
  end

  def to_s
    inner
  end

  def <<(output)
    @children << output
    self
  end
end
