# repo_compiled.rb

require 'repo'

Commit = Struct.new(:oid, :time, :message, :files, :size)
RepoFile = Struct.new(:name, :size)

class RepoCompiled < Repo
  def initialize
    super(ENV["compiled"])
  end

  def summary
    return @summary if @summary
    stop_words = [
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
    @summary = commits.map do |c|
      tree = c.tree
      files = tree.map do |f|
        name = f[:name]
        size = lookup(f).size
        stop_words.include?(name) || (name == "code.js" && size == 45) ?
          nil :
          RepoFile.new(name, size)
      end.compact
      unless files.map(&:name).include?("code.js")
        files << RepoFile.new("code.js", 278112)
      end
      size = files.map(&:size).inject(0, &:+)
      Commit.new(c.oid, c.time, c.message, files, size)
    end
  end

  def all_names
    puts "under rfs"
    names = Set.new
    summary.each do |c|
      names.merge(c.files.map(&:name))
    end
    names
  end

  def graph_data
    summary.map{|c| [c.time, c.size]}
  end
end

__END__

[6] pry(main)> File.read("/Users/rd/Dropbox/_js/code281.js").size
=> 278112