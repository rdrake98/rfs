# repo_rubyf.rb

require 'repo'
require 'changeset'

RubySave = Struct.new(:time, :json, :changeset)

class RepoRubyf < Repo
  def self.test
    mg = new("/Users/rd/ww/rubyf", 26)
    c = mg.summary.last
    puts c.time
    puts c.changeset.titles.size
    puts c.changeset.deleted.size
    mp = new("/Users/rd/ww/rubyf_mp")
    c = mp.summary.last
    puts c.time
    puts c.changeset.titles.size
    puts c.changeset.deleted.size
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
      json = lookup(find_name(lookup(dir), "fat.json")).text
      (changeset = Changeset.new).add_tiddlers(json, false)
      RubySave.new(c.time, json, changeset)
    end
  end
end
