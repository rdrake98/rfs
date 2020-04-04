# show_links.rb

require 'json'

Dir.chdir("/Users/rd/Dropbox/_shared/link_data/backups")
names = Dir.glob("s*p.js").sort.reverse
json = File.read(names[0])[2..-1]
puts "#{names[0][0..-4]}: #{"%.#{3}g" % (json.size/1000000.0)}MB"
sessions = JSON.parse(json)["sessions"]
windows = sessions[0]["windows"]
puts "#{sessions.size} sessions, #{windows.size} windows in current"
tabs = windows[0]["tabs"]
puts tabs[-1]
