# show_links.rb

require 'json'

dir = "/Users/rd/Dropbox/_shared/link_data"
json = File.read("#{dir}/backups/sp190209.225854.js")[2..-1]
puts "#{json.size} bytes of json"
begin
  backup = JSON.parse(json)
rescue => e
  puts e.class
  puts e.message.size
  puts e.message[0..200]
  puts
  puts e.message[-200..-1]
  puts
  # puts e.message
end
sessions = backup["sessions"]
puts "#{sessions.size} sessions"
sessions.group_by {|s| s["type"]}.each {|t, list| puts "#{t} #{list.size}"}
current = sessions[0]
windows = current["windows"]
puts "#{windows.size} windows in current session"
