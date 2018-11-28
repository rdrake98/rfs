# repo_rubyf.rb

require 'repo'
require 'json'

RubySave = Struct.new(:time, :changes)

class RepoRubyf < Repo
  def self.test
    mg = new("/Users/rd/ww/rubyf", 32)
    c = mg.summary.last
    puts c.time
    puts c.changes.size
    mp = new("/Users/rd/ww/rubyf_mp")
    c = mp.summary.last
    puts c.time
    puts c.changes.size
    [mg, mp]
  end

  def find_name(tree, name)
    tree.each do |hash|
      return hash if hash[:name] == name
    end
    nil
  end

  def summary
    return @summary if @summary
    @summary = commits.select {|c| c.message == "before fat saved\n"}.map do |c|
      dir = find_name(lookup(find_name(c.tree, "_data")), "_changes")
      blob = lookup(find_name(lookup(dir), "fat.json"))
      RubySave.new(c.time, JSON.parse(blob.text))
    end
  end
end
