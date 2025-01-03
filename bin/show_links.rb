# show_links.rb

require 'base'
require 'json'

Dir.cd(:tab_backups).glob("s*p.js").each do |name|
  json = File.read(name)[2..-1]
  sessions = JSON[json]["sessions"]
  windows = sessions[0]["windows"]
  tab = windows[0]["tabs"][-1]
  puts "%s: %.3gMB, %s sessions, %s windows in current" %
    [name[0..-4], json.size/1000000.0, sessions.size, windows.size],
    %w[windowId index id title].map{|s| tab[s]}.join(", "), ""
end
