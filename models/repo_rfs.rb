# repo_rfs.rb

require 'base'
require 'repo'

class RepoRfs < Repo
  def initialize
    super Dir.rfs
  end

  def summary
    return @summary if @summary
    # puts commits.size
    @summary = commits[5..-1].map do |c|
      tree = c.tree
      # puts
      # puts ("%03i " % n) + c.time.dotted #, c.message
      files = tree.map do |f|
        name = f[:name]
        # puts name
        lf = lookup(f)
        lf.is_a?(Rugged::Tree) ?
          name == "assets" ?
            nil :
            lf.map do |f|
              name = f[:name]
              lf = lookup(f)
              # puts name if lf.is_a?(Rugged::Tree)
              lf.is_a?(Rugged::Tree) ? nil : RepoFile.new(name, lf.size)
            end :
          name =~ /.txt$/ ?
            nil :
            RepoFile.new(name, lf.size)
      end.flatten.compact
      size = files.map(&:size).inject(0, &:+)
      Commit.new(c.oid, c.time, c.message, files, size)
    end
  end

  def graph_data(points=nil)
    data = summary.map{|c| [c.time, c.size]}
    points ? data[0..points] : data
  end
end
