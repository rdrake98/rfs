# show_windows.rb

require 'json'

Backup = Struct.new(:name, :windows)
Dir.chdir(ENV['tab_backups'])
backups = Dir.glob("s*p.js").sort.map do |name| Backup.new(name[0..-4],
  JSON.parse(File.read(name)[2..-1])["sessions"][0]["windows"].map{|w|w['id']})
end
puts backups
