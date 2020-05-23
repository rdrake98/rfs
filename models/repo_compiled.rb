# repo_compiled.rb

require 'base'
require 'repo'

class RepoCompiled < Repo
  @@stop_words = [
    ".gitignore",
    "loadspeed.js", "render.js", "test.js", "tests.js", "runner.js",
    "write_links.js", "write_output.js",
    "scratchpad.js",
    "scratchpad10.js",
    "scratchpad11.js",
    "scratchpad12.js",
    "scratchpad2.js",
    "scratchpad3.js",
    "scratchpad4.js",
    "scratchpad5.js",
    "scratchpad6.js",
    "scratchpad7.js",
    "scratchpad8.js",
    "scratchpad9.js",
    "example.png",
    "hello.js", "title.js",
    "code281.js"
  ]

  def initialize
    super Dir.compiled
  end

  def calc_files(c)
    files = summary_for_tree(c.tree).flatten.compact
    unless files.map(&:name).include?("code.js")
      files << RepoFile.new("code.js", 278112)
    end
    files
  end

  def file_unwanted?(name, size)
    @@stop_words.include?(name) || (name == "code.js" && size == 45)
  end

  def all_names
    puts "under rfs"
    names = Set.new
    summary.each do |c|
      names.merge(c.files.map(&:name))
    end
    names
  end
end

__END__

[6] pry(main)> File.read("/Users/rd/Dropbox/_js/code281.js").size
=> 278112
