# show_backups.rb

require 'base'
require 'json'

names = []
Dir.cd :tab_backups
Dir.glob("s*.js").each do |name|
  names << name[1..6] + name[8..9] + name[14]
  unless ARGV[0]
    windows = JSON[(File.read(name)[2..-1])]["sessions"][0]["windows"]
    tabs = windows.map {|win| win["tabs"]}.flatten.size
    machine = "m#{name[14]}"
    time = Time.parse(name[1..13].gsub('.',' ')).strftime("%d %b %H:%M")
    puts "%s %s: %2d windows, %3d tabs" % [time, machine, windows.size, tabs]
  end
end
print names.size
duplicates = names.size - names.uniq.size
puts " " + (duplicates > 0 ? "** #{duplicates} duplicates **" : "")
