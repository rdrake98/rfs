# show_links.rb

require 'external_link'
require 'json'

json = File.read('../link_data/s190811_213447.json')[2..-2]
puts json.size
backup = JSON.parse(json)
sessions = backup["sessions"]
puts sessions.size
puts sessions.map {|s| s["type"]}.uniq
current = sessions[0]
windows = current["windows"]
puts windows.size
