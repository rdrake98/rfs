# repo.rb

require 'base'
require 'rugged'

Commit = Struct.new(:oid, :time, :message, :files, :size)
RepoFile = Struct.new(:name, :size)

class Repo
  def initialize(dir, unwanted_dir=nil)
    @repo = Rugged::Repository.new(dir)
    @unwanted_dir = unwanted_dir
  end

  def commits
    @commits || recalc_commits
  end

  def recalc_commits
    @summary = nil
    walker = Rugged::Walker.new(@repo)
    walker.push(@repo.head.target_id)
    @commits = []
    walker.each { |c| @commits << c; break if @commits.size >= 999999 }
    @commits
  end

  def summary_for_tree(tree)
    files = tree.map do |f|
      name = f[:name]
      lf = lookup(f)
      lf.is_a?(Rugged::Tree) ?
        name =~ @unwanted_dir ?
          nil :
          summary_for_tree(lf) :
        RepoFile.new(name, lf.size)
    end
  end

  def summary
    return @summary if @summary
    @summary = commits.map do |c|
      files = summary_for_tree(c.tree).flatten.compact
      Commit.new(c.oid, c.time, c.message, files, files.map(&:size).sum)
    end
  end

  def graph_data(n=nil, last_oid=nil)
    i = last_oid && commits.index{|c| c.oid =~ /^#{last_oid}/} || 0
    subset = summary[i..(n ? i+n-1 : -1)]
    c = subset[0]
    puts "", c.oid, c.time.to_minute, c.message, c.size, ""
    c = subset[-1]
    puts c.oid, c.time.to_minute, c.message, c.size, ""
    subset.map{|c| [c.time, c.size]}
  end

  def lookup(hash)
    @repo.lookup(hash[:oid])
  end
end
