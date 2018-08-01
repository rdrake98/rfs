require 'roda'
require 'splitter'
require 'chartkick'
require 'repo'

$wikis = {"fat" => Splitter.fat, "dev" => Splitter.dev}
puts $wikis["fat"].edition
puts $wikis["dev"].edition
$repo = Repo.new

class App < Roda
  plugin :render
  plugin :assets, js: ['Chart.bundle.min.js', 'chartkick.js']
  plugin :h
  route do |r|
    r.assets
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type]
        message = "#{p['title']} #{p['action']} in #{wiki_type}"
        puts message
        wiki.add_changes(p['changes']) if wiki
        message
      end

      r.post "save" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type] || Splitter.new(wiki_type)
        puts "saving #{wiki_type}"
        wiki.save(p['changes'])
      end
    end

    r.get "graph" do
      chartkick = Class.new.include(Chartkick::Helper).new
      view('graph', locals: {chartkick: chartkick, data: $repo.graph_data})
    end
  end
end
