# show_links.rb

require 'json'

dir = "/Users/rd/Dropbox/_shared/link_data"
json = File.read("#{dir}/backups/s200310.030533g.js")[2..-1]
puts "#{json.size} bytes of json"
backup = JSON.parse(json)
sessions = backup["sessions"]
puts "#{sessions.size} sessions"
sessions.group_by {|s| s["type"]}.each {|t, list| puts "#{t} #{list.size}"}
current = sessions[0]
windows = current["windows"]
puts "#{windows.size} windows in current session"
