# add_links.rb

require 'splitter'

googling = dev = false
ARGV.each_with_index do |arg, i|
  if arg[0] == "-"
    googling = "g".in? arg
    dev = "d".in? arg
    ARGV.delete_at(i)
    break
  end
end
Dir.chdir('/Users/rd/Dropbox/_shared/link_data/exports')
names = Dir.glob("*.txt").reverse
name = names.find {|n| File.read(n).lines[0][2..-2] == ARGV[0]}
print ARGV[0]
unless name
  puts(" not found")
  Dir.chdir("/Users/rd/rf/rfs")
  return
end
puts "", name
`cp #{name} ~/rf/link_data/steps/exports`
lines = File.read(name).lines[1..-1]
fml = lines.each_slice(3).map {|s| s[1].strip.link(s[2].strip)}.join("\n")
tiddler_name = ARGV[1] || ARGV[0]
puts tiddler_name
wiki = nil
if googling
  puts "googling"
  puts "dev" if dev
  wiki = dev ? Splitter.dev : Splitter.fat
end
Dir.chdir("/Users/rd/rf/link_data/steps/fml")
Tiddler.new(wiki, tiddler_name, fml).write_mini(googling)
Dir.chdir("../../../rfs")
