require 'roda'
require 'wiki_with_tabs_sb'

class App < Roda
  puts "restarting rfs"
  puts ENV["RUBYLIB"]
  Wikis = {}

  def reload(type="fat", saving=true, edition=nil, changes=nil)
    puts "reloading #{type} into server from file"
    wiki = type == "fat" ? Splitter.fat : Splitter.dev
    Wikis[type] = wiki
    saving ? edition ? wiki.save(edition, changes) : wiki.do_save : wiki
  end

  def wrong_edition?(wiki, latest_edition=nil)
    return true unless wiki
    wiki.edition != (latest_edition || wiki.read_file_edition)
  end

  def wiki(type, strict=false)
    return Wikis[type] if Wikis[type]
    wiki = (type == "fat" ? Splitter.fat :
      type == "dev" ? Splitter.dev :
      strict ? nil : Splitter.new(type))
    Wikis[type] = wiki if wiki
    wiki
  end

  route do |r|
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        type = p['type']
        message = "#{p['title']} #{p['action']} in #{type}"
        puts message
        wiki(type, true)&.add_changes(p['changes'], p['shared'] == "true")
        message
      end

      r.post "save" do
        p = r.params
        type, edition, changes = p['type'], p['edition'], p['changes']
        wiki(type).save(edition, changes) ||
          reload(type, true, edition, changes)
      end

      r.post "link" do
        # byebug if $dd
        response = {}
        p = r.params
        type, title, name, target, edition =
          p['type'], p['title'], p['name'], p['target'], p['edition']
        target = nil if target == ""
        insert = target ? ' with ' + target : ''
        puts "#{p['action']} '#{name}'#{insert} in #{title} in #{type}"
        normal = wiki(type, true)
        wiki = wiki(type)
        clash = wiki.check_file_edition(edition)
        if clash
          response["clash"] = clash.split(",")[0]
        else
          wiki = reload(type, false) if normal && wrong_edition?(wiki, edition)
          wiki.add_tiddlers(p['changes'])
          unlink = p['unlink'] == "true"
          overlink = p['overlink'] == "true"
          new_text, replacer = wiki[title].link(name, target, unlink, overlink)
          response["newText"] = new_text
          response["replacer"] = replacer
        end
        response.to_json
      end

      r.post "medit" do
        # byebug if $dd
        response = {}
        p = r.params
        type, title, edition = p['type'], p['title'], p['edition']
        puts "medit on #{title} in #{type}"
        normal = wiki(type, true)
        wiki = wiki(type)
        clash = wiki.check_file_edition(edition)
        if clash
          response["clash"] = clash.split(",")[0]
        else
          wiki = reload(type, false) if normal && wrong_edition?(wiki, edition)
          wiki.add_tiddlers(p['changes'])
          new_text, replacer = wiki[title].medit
          response["newText"] = new_text
          response["replacer"] = replacer
        end
        response.to_json
      end

      r.post "other_changes" do
        p = r.params
        type = p['type']
        change_type = p['change_type']
        wiki = wiki(type, true)
        wiki = reload(type, false) if wrong_edition?(wiki)
        if change_type == "wiki"
          puts "serving changes from m#{wiki.other_host} for #{type} on startup"
        else
          puts "adding links"
        end
        wiki.other_changes(change_type)
      end

      r.post "seed" do
        p = r.params
        type = p['type']
        wiki = wiki(type) # type is checked in javascript
        if wiki.check_file_edition(p['edition'])
          "version clash"
        else
          `cp $#{type} $data/#{type}_.html`
          File.write(Dir.data("#{type}_output.html"), p['output'])
          puts "#{type}_ and #{type}_output written"
          "seed success"
        end
      end
    end

    r.get "copy_backups" do
      WikiWithTabsSB.copy_backups
    end

    r.get "tabs" do
      WikiWithTabsSB.new.show_final_tabs.to_s
    end

    r.get "tabs_combined" do
      WikiWithTabsSB.new(0).show_final_tabs.to_s
    end

    r.get "unpeel" do
      WikiWithTabsSB.unpeel
    end

    r.get "copy_tabs_to_fat" do
      WikiWithTabsSB.copy_to_fat
      "copy_to_fat complete"
    end

    r.get "commit_tabs_mods" do
      WikiWithTabsSB.commit_mods
    end
  end
end
