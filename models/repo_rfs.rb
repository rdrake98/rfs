# repo_rfs.rb

require 'base'
require 'repo'

class RepoRfs < Repo
  def initialize
    super Dir.rfs, /^(assets|tab_filters|foo)$/
  end
end
