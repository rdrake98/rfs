# show_backups.rb

require 'json'
require 'date'

Dir.chdir(ENV['tab_backups'])
Dir.glob("s*.js").sort.each do |name|
  windows = JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"]
  tabs = windows.map {|win| win["tabs"]}.flatten.size
  machine = "m#{name[14]}"
  time = DateTime.parse("#{name[1..6]} #{name[8..13]}").strftime("%d %b %H:%M")
  puts "%s %s: %2d windows, %3d tabs" % [time, machine, windows.size, tabs]
end
