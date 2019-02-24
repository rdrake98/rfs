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

  def load_and_save(wiki_type="fat", p=nil)
    puts "reloading #{wiki_type}"
    wiki = wiki_type == "fat" ? Splitter.fat : Splitter.dev
    $wikis[wiki_type] = wiki
    p ? wiki.save(p['edition'], p['changes']) : wiki.do_save
  end

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

      r.post "link" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type] || Splitter.new(wiki_type)
        title = p['title']
        name = p['name']
        message = "#{p['action']} '#{name}' in #{title} in #{wiki_type}"
        puts message
        new_text = wiki[title].link(name)
        compare = new_text == p['newText'] ? "same" : "different"
        puts compare
        compare
      end

      r.post "save" do
        p = r.params
        wiki_type = p['wiki']
        wiki = $wikis[wiki_type] || Splitter.new(wiki_type)
        puts "saving #{wiki_type}"
        wiki.save(p['edition'], p['changes']) || load_and_save(wiki_type, p)
      end
    end

    r.get "graph" do
      chartkick = Class.new.include(Chartkick::Helper).new
      view('graph', locals: {chartkick: chartkick, repo: $repo})
    end

    r.get "sync" do
      $wikis["fat"].sync
    end

    r.get "force" do
      load_and_save # fat only for now
      "hopefully not lost anything"
    end
  end
end
