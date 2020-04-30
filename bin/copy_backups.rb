# copy_backups.rb

require 'base'

def s6(name, i); name[i..i+1] + name[i+3..i+4] + name[i+6..i+7]; end

Dir.chdir('/Users/rd/Downloads')
to = "~/rf/link_data/copied"
Dir.glob("session_buddy_backup_*.json").sort.each do |name|
  `cp -p #{name} #{to}/s#{s6(name, 23)}.#{s6(name, 32)}#{hostc}.js`
end
puts `rsync -a --out-format=%n%L #{to}/* $tab_backups/`
