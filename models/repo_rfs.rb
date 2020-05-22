# repo_rfs.rb

require 'base'
require 'repo'

class RepoRfs < Repo
  def initialize
    super Dir.rfs
  end

  def summary
    return @summary if @summary
    @summary = commits.map do |c|
      files = summary_for_tree(c.tree).flatten.compact
      Commit.new(c.oid, c.time, c.message, files, files.map(&:size).sum)
    end
  end
end
