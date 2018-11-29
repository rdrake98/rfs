# repo_rubyf.rb

require 'repo'
require 'changeset'

RubySave = Struct.new(:time, :changeset)

class RepoRubyf < Repo
  def self.test
    mg = new("/Users/rd/ww/rubyf", 26)
    mg.show
    mp = new("/Users/rd/ww/rubyf_mp")
    mp.show
    [mg, mp]
  end

  def show
    c = summary.last
    puts c.time
    puts c.changeset.titles.size
    puts c.changeset.deleted.size
  end

  def lookup_name(tree, name)
    lookup(tree.find{|hash| hash[:name] == name})
  end

  def summary
    return @summary if @summary
    @summary = commits.select {|c| c.message == "before fat saved\n"}.map do |c|
      dir = lookup_name(lookup_name(c.tree, "_data"), "_changes")
      json = lookup_name(dir, "fat.json").text
      RubySave.new(c.time, Changeset.new(json))
    end
  end
end
