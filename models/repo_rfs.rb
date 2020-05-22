# repo_rfs.rb

require 'base'
require 'repo'

class RepoRfs < Repo
  def initialize
    super Dir.rfs
  end

  def summary_for_tree(tree)
    files = tree.map do |f|
      name = f[:name]
      lf = lookup(f)
      lf.is_a?(Rugged::Tree) ?
        name == "assets" || name == "tab_filters" || name == "foo" ?
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
end
