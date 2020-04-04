# show_links.rb

require 'json'

dir = "/Users/rd/Dropbox/_shared/link_data"
json = File.read("#{dir}/backups/s200402.232908p.js")[2..-1]
puts "#{json.size} bytes of json"
sessions = JSON.parse(json)["sessions"]
puts "#{sessions.size} sessions"
windows = sessions[0]["windows"]
puts "#{windows.size} windows in current session"
tabs = windows[0]["tabs"]
puts tabs[-1]
