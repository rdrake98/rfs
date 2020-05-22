# repo.rb

require 'rugged'

Commit = Struct.new(:oid, :time, :message, :files, :size)
RepoFile = Struct.new(:name, :size)

class Repo
  def initialize(dir, limit=999999)
    @repo = Rugged::Repository.new(dir)
    @limit = limit
  end

  def commits
    @commits || recalc_commits
  end

  def recalc_commits
    @summary = nil
    walker = Rugged::Walker.new(@repo)
    walker.push(@repo.head.target_id)
    @commits = []
    walker.each { |c| @commits << c; break if @commits.size >= @limit }
    @commits
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
