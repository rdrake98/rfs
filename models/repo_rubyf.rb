# repo_rubyf.rb

require 'repo'
require 'changeset'
require 'splitter'

RubySave = Struct.new(:time, :changeset)

class RepoRubyf < Repo
  def self.probe
    tiddlers = Hash.new{[]}
    new("/Users/rd/ww/rubyf", 26).add_changes_to(tiddlers)
    puts tiddlers.size
    new("/Users/rd/ww/rubyf_mp").add_changes_to(tiddlers)
    puts tiddlers.size
    tiddlers.each{|k,v| v.sort_by!(&:modified)}
    volumes = Hash.new{[]}
    tiddlers.each {|k,v| volumes[v.size] <<= k}
    p volumes.keys.sort.map {|k| [k, volumes[k].size]}
    fat = Splitter.fat
    missing = []
    different = []
    tiddlers.each do |title, changes|
      tiddler_now = fat[title]
      if tiddler_now
        different << title if tiddler_now.content != changes.last.content
      else
        missing << title
      end
    end
    puts missing.size
    puts different.size
    {
      tiddlers: tiddlers,
      volumes: volumes,
      missing: missing,
      different: different
    }
  end

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

  def add_changes_to(hash)
    summary.each {|save| save.changeset.tiddlers.each {|t| hash[t.title] <<= t}}
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
