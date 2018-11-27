# repo.rb

require 'rugged'

Commit = Struct.new(:oid, :time, :message, :files, :size)
RepoFile = Struct.new(:name, :size)

class Repo

  def initialize(dir=ENV["compiled"], limit=999999)
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
end
