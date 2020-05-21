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
      tree = c.tree
      files = tree.map do |f|
        name = f[:name]
        lf = lookup(f)
        lf.is_a?(Rugged::Tree) ?
          name == "assets" || name == "tab_filters" ?
            nil :
            lf.map do |f|
              name = f[:name]
              lf = lookup(f)
              lf.is_a?(Rugged::Tree) ? nil : RepoFile.new(name, lf.size)
            end :
          RepoFile.new(name, lf.size)
      end.flatten.compact
      size = files.map(&:size).inject(0, &:+)
      Commit.new(c.oid, c.time, c.message, files, size)
    end
  end
end
