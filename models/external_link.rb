# external_link.rb

class ExternalLink
  attr_reader :url, :text
  attr_accessor :wanted

  def initialize(url, text)
    @url, @text = url, text
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
end

class ExternalLinkLine < ExternalLink
  attr_reader :content

  def initialize(content)
    @content = content
    url, text = content =~ /^\[\[(.*)\|(.*)\]\]/ && [$2, $1]
    super(url, text)
  end
end

class ExternalLinkSB < ExternalLink
  def initialize(tab)
    super(tab["url"], tab["title"])
  end

  def content
    @text.link(@url)
  end
end
