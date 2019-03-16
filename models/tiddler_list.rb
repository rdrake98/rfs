# tiddler_list.rb

require 'set'

class TiddlerList
  @lists = Hash.new{[]}

  def self.path(name, dir="_lists/", ext="txt")
    "#{ENV["data"]}/#{dir}#{name}.#{ext}"
  end

  def self.html_path(suffix="_fail", dir="_rb/")
    path("fat#{suffix}", dir, "html")
  end

  def self.names_from(path)
    Regex.scan_output(path).map {|name, output| name}
  end

  def self.set_git(tag, silent=false)
    `cd #{ENV["data"]}; git checkout #{tag}#{silent ? ' &>/dev/null' : ''}`
  end

  def self.setup
    set_git(git_tag)
    fat = Splitter.new(html_path("_", ""))
    excluded = fat.titles_linked("MacrosNotTo") +
      fat.titles_linked("AcceptableDifferences")
    if !mp?
      self._all = names_from(html_path("_output", "")) - excluded
      set_git("apr01")
      self._all1 = names_from(html_path("_output", "")) - excluded
      self._fail1 = names_from(html_path) - excluded
      set_git("mar23")
      self._all2 = names_from(html_path("_output", "")) - excluded
      self._fail2 = (1..154).map do |n|
        path_rb = html_path(sprintf('%03i',n))
        path_js = path_rb.gsub(/rb/, "js")
        js_hash = {}
        Regex.scan_output(path_js).each {|name, output| js_hash[name] = output}
        Regex.scan_output(path_rb).
          select{|name, output| output != js_hash[name]}.map{|name, output| name}
      end.flatten - excluded
    end
    self._excluded = excluded
    self._shadows = fat["ShadowTiddlersFinal"].content.split("\n")
    set_git(git_branch)
    fat
  end

  def self.write
    @lists.each do |key, list|
      File.open(path(key), 'w') {|file| file.puts(list)}
    end
  end

  def self.[](key)
    list = @lists[key]
    list.size == 0 && key[0..1] != "__" ? self[:"_#{key}"] : list
  end

  def self.[]=(key, list); @lists[key] = list; end

  def self.method_missing(name, *args)
    args.size == 0 ?
      self[name] :
      name[-1] == "=" ? self[name[0..-2].to_sym] = args[0] : nil
  end

  Dir.glob(path("*")).each do |full_path|
    key = full_path.split("/")[-1][0...-4].to_sym
    self[key] = File.read(full_path).split("\n")
  end

  def self.shadows; self[:_shadows]; end

  def self.show(*names)
    names = @lists.keys if names.size == 0
    names.each {|name| puts "#{name}: #{self[name].size}"}
  end

  def self.segment(limit1, limit2)
    # used segment 200, 1000;
    names = @lists.keys.reject {|name| name[0] == "_"}
    smalln = names.select {|name| self[name].size <= limit1}
    largen = names.select {|name| self[name].size > limit2}
    midn = names - smalln - largen
    small = smalln.map {|name| self[name]}.flatten.to_set
    mid = midn.map {|name| self[name]}.flatten.to_set - small
    self.__small = (small | fail1 & all).to_a.sort # some tiddlers were deleted
    self.__mid = ((mid | fail2 & all) - self.small).to_a.sort
    self.__large = all - self.small - self.mid
  end

  def self.sample
    small.sample(300) + mid.sample(500) + large.sample(107)
  end
end
