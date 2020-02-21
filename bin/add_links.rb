# show_links.rb

require 'external_link'
require 'json'
require 'tiddler'

Dir.chdir('../link_data/exports')
names = Dir.glob("*.txt").reverse
name = names.find {|n| File.read(n).lines[0][2..-2] == ARGV[0]}
print ARGV[0]
unless name
  puts(" not found")
  Dir.chdir("../../rfs")
  return
end
puts "", name
`cp #{name} ../steps/exports`
lines = File.read(name).lines[1..-1]
fml = lines.each_slice(3).map {|s| "[[#{s[1].strip}|#{s[2].strip}]]"}
fml = fml.join("\n")
tiddler_name = ARGV[1] || ARGV[0]
Dir.chdir("../steps/fml")
# Tiddler.new(nil, tiddler_name, fml).write_mini
puts tiddler_name
Dir.chdir("../../../rfs")
