# show_links.rb

require 'json'

Dir.chdir("/Users/rd/Dropbox/_shared/link_data/backups")
Dir.glob("s*p.js").sort.each do |name|
  json = File.read(name)[2..-1]
  sessions = JSON.parse(json)["sessions"]
  windows = sessions[0]["windows"]
  tab = windows[0]["tabs"][-1]
  puts "%s: %.3gMB, %s sessions, %s windows in current" %
    [name[0..-4], (json.size/1000000.0), sessions.size, windows.size],
    %w[windowId index id title].map{|s|tab[s]}.join(", "), ""
end
