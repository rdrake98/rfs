require 'roda'
require 'splitter'
require 'chartkick'
require 'repo_compiled'

$wikis = {"fat" => Splitter.fat, "dev" => Splitter.dev}
puts $wikis["fat"].edition
puts $wikis["dev"].edition
$repo = RepoCompiled.new

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
        response = wiki.save(p['edition'], p['changes'])
        unless response
          puts "reloading #{wiki_type}"
          $wikis[wiki_type] = wiki_type == "fat" ? Splitter.fat : Splitter.dev
          response = $wikis[wiki_type].save(p['edition'], p['changes'])
        end
        response
      end
    end

    r.get "graph" do
      chartkick = Class.new.include(Chartkick::Helper).new
      view('graph', locals: {chartkick: chartkick, repo: $repo})
    end

    r.get "sync" do
      $wikis["fat"].sync
    end
  end
end
