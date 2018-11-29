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

  def lookup_name(tree, name)
    lookup(tree.find{|hash| hash[:name] == name})
  end

  def summary
    return @summary if @summary
    @summary = commits.select {|c| c.message == "before fat saved\n"}.map do |c|
      dir = lookup_name(lookup_name(c.tree, "_data"), "_changes")
      json = lookup_name(dir, "fat.json").text
      RubySave.new(c.time, json, Changeset.new(json))
    end
  end
end
