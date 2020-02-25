# add_links.rb

require 'splitter'

Dir.chdir('../link_data/exports')
names = Dir.glob("*.txt").reverse
googling = false
ARGV.each_with_index do |arg, i|
  if arg == "-g"
    googling = true
    ARGV.delete_at(i)
  end
end
dev = false
ARGV.each_with_index do |arg, i|
  if arg == "-d"
    dev = true
    ARGV.delete_at(i)
  end
end
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
puts tiddler_name
wiki = nil
if googling
  puts "googling"
  puts "dev" if dev
  wiki = dev ? Splitter.dev : Splitter.fat
end
Dir.chdir("../steps/fml")
Tiddler.new(wiki, tiddler_name, fml).write_mini(googling)
Dir.chdir("../../../rfs")
