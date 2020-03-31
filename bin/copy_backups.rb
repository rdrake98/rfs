# copy_backups.rb

require 'base'

def s6(name, i)
  name[i..i+1] + name[i+3..i+4] + name[i+6..i+7]
end

from = '/Users/rd/Downloads'
to = "~/rf/link_data/copied"
final = ""
Dir.chdir(from)
Dir.glob("session_buddy_backup_*.json").sort.each do |name|
  short_name = "s#{s6(name, 23)}.#{s6(name, 32)}#{hostc}.js"
  `cp -p #{name} #{to}/#{short_name}`
end
puts `rsync -a --out-format=%n%L #{to}/* ~/Dropbox/_shared/link_data/backups/`
