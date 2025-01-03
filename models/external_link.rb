# external_link.rb

class ExternalLink
  attr_reader :url, :text
  attr_accessor :wanted

  def initialize(tab)
    @url, @text = tab["url"], tab["title"]
    @wanted = !@url.nil?
  end

  def before_q(url)
    url=~/^(.*)\?/ && $1
  end

  def preamble
    @preamble || @preamble = before_q(@url)
  end

  def preamble_matches?(url2)
    preamble && url2.start_with?(@preamble) || before_q(url2) == @url
  end

  def before_hash(url)
    url=~/^(.*)\#/ && $1
  end

  def pre_hash
    @pre_hash || @pre_hash = before_hash(@url)
  end

  def pre_hash_matches?(url2)
    pre_hash && url2.start_with?(@pre_hash) || before_hash(url2) == @url
  end
  
  def content
    @text.link(@url) + "\n"
  end
end
