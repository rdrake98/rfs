# show_windows.rb

require 'json'

Backup = Struct.new(:name, :windows)
Dir.chdir(ENV['tab_backups'])
backups = Dir.glob("s*p.js").sort.map do |name|
  json = File.read(name)[2..-1]
  ids = JSON.parse(json)["sessions"][0]["windows"].map{|win| win['id']}
  Backup.new(name[0..-4], ids)
end
Sequence = Struct.new(:id, :length, :backup1, :backup2)
sequences = []
previous = nil
backups.each do |backup|
  name = backup.name
  backup.windows.each do |id|
    prev = sequences.find {|seq| seq.id == id && seq.backup2 == previous}
    if prev
      prev.backup2 = name
      prev.length += 1
    else
      sequences << Sequence.new(id, 1, name, name)
    end
  end
  previous = name
end
puts sequences