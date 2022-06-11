require 'roda'
require 'wiki_with_tabs'

class Wany < Roda
  puts "restarting wany"
  puts ENV["RUBYLIB"]
  Fat = Splitter.fat
  puts Fat.tiddlers.size

  route do |r|
    # r.on "public" do
    #   r.post "search" do
    #     response = {}
    #     p = r.params
    #     type, name, regex, caseSensitive, edition =
    #       p['type'], p['name'], p['regex'], p['case'], p['edition']
    #     puts "searching for '#{name}' using '#{regex}' in #{type}"
    #     response.to_json
    #   end
    # end

    r.get "show" do
      Fat.tiddlers.size.to_s
    end
  end
end
