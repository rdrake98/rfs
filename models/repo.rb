# repo.rb

require 'rugged'

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

  def lookup(hash)
    @repo.lookup(hash[:oid])
  end
end