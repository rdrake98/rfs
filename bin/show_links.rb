# show_links.rb

require 'json'

Dir.chdir("/Users/rd/Dropbox/_shared/link_data/backups")
Dir.glob("s*p.js").sort.each do |name|
  json = File.read(name)[2..-1]
  sessions = JSON.parse(json)["sessions"]
  windows = sessions[0]["windows"]
  tab = windows[0]["tabs"][-1]
  puts "#{name[0..-4]}: #{'%.3g' % (json.size/1000000.0)}MB, " +
    "#{sessions.size} sessions, #{windows.size} windows in current"
  puts [tab['windowId'], tab['index'], tab['id'], tab['title']].join(", "), ""
end
