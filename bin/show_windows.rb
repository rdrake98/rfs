# show_windows.rb

require 'json'

Dir.chdir(ENV['tab_backups'])
Dir.glob("s*p.js").sort.each do |name|
  windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
  puts "%s: %s" % [name[0..-4], windows.size]
  puts windows.map{|w|w['id']}.join(", ")
  puts
end
