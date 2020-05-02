# show_sessions.rb

require 'json'

json = File.read("#{ENV['tab_backups']}/s200402.232908p.js")[2..-1]
puts "#{json.size} bytes of json"
sessions = JSON.parse(json)["sessions"]
types = sessions.group_by {|s| s["type"]}.map {|t, l| ", #{l.size} #{t}"}.join
puts "#{sessions.size} sessions#{types}"
current = sessions[0]
windows = current["windows"]
puts "#{windows.size} windows in current session"
