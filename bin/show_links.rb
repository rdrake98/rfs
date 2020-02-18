# show_links.rb

require 'external_link'
require 'json'

json = File.read('../link_data/backups/s190811_213447.json')[2..-2]
puts "#{json.size} bytes of json"
backup = JSON.parse(json)
sessions = backup["sessions"]
puts "#{sessions.size} sessions"
sessions.group_by {|s| s["type"]}.each {|t, list| puts "#{t} #{list.size}"}
current = sessions[0]
windows = current["windows"]
puts "#{windows.size} windows in current session"
