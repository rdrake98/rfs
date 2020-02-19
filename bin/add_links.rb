# show_links.rb

require 'external_link'
require 'json'

Dir.chdir('../link_data/exports')
names = Dir.glob("*.txt").reverse
contents = names.map {|n| File.read(n)[2..-1]}
target = contents.find {|c| c.lines[0].chomp == ARGV[0]}
return unless target
puts target&.size

# puts "#{json.size} bytes of json"
# backup = JSON.parse(json)
# sessions = backup["sessions"]
# puts "#{sessions.size} sessions"
# sessions.group_by {|s| s["type"]}.each {|t, list| puts "#{t} #{list.size}"}
# current = sessions[0]
# windows = current["windows"]
# puts "#{windows.size} windows in current session"
