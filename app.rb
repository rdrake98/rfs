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

  def reload(type="fat", saving=true, edition=nil, changes=nil)
    puts "reloading #{type}"
    wiki = type == "fat" ? Splitter.fat : Splitter.dev
    $wikis[type] = wiki
    saving ? edition ? wiki.save(edition, changes) : wiki.do_save : wiki
  end

  route do |r|
    r.assets
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        type = p['type']
        wiki = $wikis[type]
        message = "#{p['title']} #{p['action']} in #{type}"
        puts message
        wiki.add_changes(p['changes']) if wiki
        message
      end

      r.post "link" do
        response = {}
        p = r.params
        type, title, name, edition = p['type'],p['title'],p['name'],p['edition']
        puts "#{p['action']} '#{name}' in #{title} in #{type}"
        wiki = $wikis[type] || (w = Splitter.new(type); type = nil; w)
        clash = wiki.check_file_edition(edition)
        if clash
          response["clash"] = clash.split(",")[0]
        else
          wiki = reload(type, false) if type && edition != wiki.edition
          wiki.add_tiddlers(p['changes'])
          new_text = wiki[title].link(name)
          compare = new_text == p['newText'] ? "same" : "different"
          puts compare
          response["compare"] = compare
          qq "p['newText']", :new_text if $d
          response["newText"] = new_text
        end
        response.to_json
      end

      r.post "save" do
        p = r.params
        type, edition, changes = p['type'], p['edition'], p['changes']
        wiki = $wikis[type] || Splitter.new(type)
        wiki.save(edition, changes) || reload(type, true, edition, changes)
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
      reload # fat only for now
      "hopefully not lost anything"
    end
  end
end
