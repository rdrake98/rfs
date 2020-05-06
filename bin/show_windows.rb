# show_windows.rb

require 'json'

Backup = Struct.new(:name, :windows)
Dir.chdir(ENV['tab_backups'])
backups = Dir.glob("s*p.js").sort.map do |name|
  json = File.read(name)[2..-1]
  ids = JSON.parse(json)["sessions"][0]["windows"].map{|win| win['id']}
  Backup.new(name[0..-4], ids)
end
Sequence = Struct.new(:id, :backup1, :backup2)
results = []
previous = nil
backups.each do |backup|
  backup.windows.each do |id|
    prev = results.find {|seq| seq.id == id && seq.backup2 == previous}
    if prev
      prev.backup2 = backup.name
    else
      results << Sequence.new(id, backup.name, backup.name)
    end
  end
  previous = backup.name
end
puts results
