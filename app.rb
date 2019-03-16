require 'roda'
require 'splitter'
require 'chartkick'
require 'repo_compiled'

class App < Roda
  plugin :render
  plugin :assets, js: ['Chart.bundle.min.js', 'chartkick.js']
  plugin :h

  WIKIS = {"fat" => Splitter.fat, "dev" => Splitter.dev}
  puts WIKIS["fat"].edition
  puts WIKIS["dev"].edition
  REPO = RepoCompiled.new

  def reload(type="fat", saving=true, edition=nil, changes=nil)
    puts "reloading #{type} into server from file"
    wiki = type == "fat" ? Splitter.fat : Splitter.dev
    WIKIS[type] = wiki
    saving ? edition ? wiki.save(edition, changes) : wiki.do_save : wiki
  end

  route do |r|
    r.assets
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        type = p['type']
        wiki = WIKIS[type]
        message = "#{p['title']} #{p['action']} in #{type}"
        puts message
        wiki.add_changes(p['changes'], p['shared'] == "true") if wiki
        message
      end

      r.post "other_changes" do
        p = r.params
        type = p['type']
        wiki = WIKIS[type]
        wiki = reload(type, false) if wiki.edition != wiki.read_file_edition
        puts "serving changes from m#{wiki.other_host} for #{type} on startup"
        wiki.other_changes
      end

      r.post "link" do
        response = {}
        p = r.params
        type, title, name, edition = p['type'],p['title'],p['name'],p['edition']
        puts "#{p['action']} '#{name}' in #{title} in #{type}"
        wiki = WIKIS[type] || (w = Splitter.new(type); type = nil; w)
        clash = wiki.check_file_edition(edition)
        if clash
          response["clash"] = clash.split(",")[0]
        else
          wiki = reload(type, false) if type && edition != wiki.edition
          wiki.add_tiddlers(p['changes'])
          unlink = p['unlink'] == "true"
          overlink = p['overlink'] == "true"
          new_text = wiki[title].link(name, unlink, overlink)
          same = new_text == p['newText']
          puts "** difference with JavaScript **" unless same
          response["compare"] = same ? "same" : "different"
          response["newText"] = new_text
        end
        response.to_json
      end

      r.post "save" do
        p = r.params
        type, edition, changes = p['type'], p['edition'], p['changes']
        wiki = WIKIS[type] || Splitter.new(type)
        wiki.save(edition, changes) || reload(type, true, edition, changes)
      end

      r.post "seed" do
        p = r.params
        type = p['type']
        wiki = WIKIS[type] # type is checked in javascript
        if wiki.check_file_edition(p['edition'])
          "version clash"
        else
          `cp $#{type} #{ENV['data']}/#{type}_.html`
          File.write("#{ENV['data']}/#{type}_output.html", p['output'])
          File.write("#{ENV['data']}/#{type}_links.txt", p['links'])
          puts "#{type}_, #{type}_output and #{type}_links written"
          "seed success"
        end
      end
    end

    r.get "graph" do
      chartkick = Class.new.include(Chartkick::Helper).new
      view('graph', locals: {chartkick: chartkick, repo: REPO})
    end

    r.get "sync" do
      WIKIS["fat"].sync
    end

    r.get "force" do
      reload # fat only for now
      "hopefully not lost anything"
    end
  end
end
