# show_windows.rb

require 'json'

Dir.chdir(ENV['tab_backups'])
Dir.glob("s*p.js").sort.each do |name|
  json = File.read(name)[2..-1]
  sessions = JSON.parse(json)["sessions"]
  windows = sessions[0]["windows"]
  tab = windows[0]["tabs"][-1]
  puts "%s: %s" % [name[0..-4], windows.size]
  puts windows.map{|w|w['id']}.join(", ")
  puts
end
