require 'roda'
require 'splitter'

class App < Roda
  puts "restarting rfs"
  puts ENV["RUBYLIB"]
  Wikis = {}

  def reload(type="fat", saving=true, edition=nil, changes=nil)
    puts "reloading #{type} into server from file"
    wiki = type == "fat" ?
      Splitter.fat :
      type == "dev" ? Splitter.dev : Splitter.new(type)
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

      r.post "order_change" do
        p = r.params
        wiki(p['type'], true)&.order_change(p['open'])
        ""
      end

      r.post "save" do
        p = r.params
        type, edition, changes = p['type'], p['edition'], p['changes']
        wiki(type).save(edition, changes) ||
          reload(type, true, edition, changes)
      end

      r.post "bulk_change" do
        # byebug if $dd
        p = r.params
        type, title, edition = p['type'], p['title'], p['edition']
        puts "bulk change based on #{title} in #{type}"
        normal = wiki(type, true)
        wiki = wiki(type)
        clash = wiki.check_file_edition(edition)
        if clash
          {"clash" => clash.split(",")[0]}.to_json
        else
          wiki = reload(type, false) if normal && wrong_edition?(wiki, edition)
          wiki.add_tiddlers(p['changes'])
          wiki[title].bulk_change
        end
      end

      r.post "link" do
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

      r.post "search" do
        response = {}
        p = r.params
        type, name, regex, caseSensitive, edition =
          p['type'], p['name'], p['regex'], p['case'], p['edition']
        puts "searching for '#{name}' using '#{regex}' in #{type}"
        normal = wiki(type, true)
        wiki = wiki(type)
        clash = wiki.check_file_edition(edition)
        if clash
          response["clash"] = clash.split(",")[0]
        else
          wiki = reload(type, false) if normal && wrong_edition?(wiki, edition)
          wiki.add_tiddlers(p['changes'])
          response["titles"] = wiki.search(regex, name, caseSensitive)
        end
        response.to_json
      end

      r.post "other_changes" do
        p = r.params
        type = p['type']
        from_self = p['from_self']
        wiki = wiki(type, true)
        wiki = reload(type, false) if wrong_edition?(wiki)
        puts "serving changes from m#{wiki.other_host} for #{type} on startup"
        wiki.other_changes(from_self.true?)
      end

      r.post "seed" do
        p = r.params
        type = p['type']
        wiki = wiki(type) # type is checked in javascript
        normal = type.size == 3
        if normal && wiki.check_file_edition(p['edition']) # never true for dev
          "version clash"
        else
          output_file = if normal
            `cp $#{type} $data/#{type}_.html`
            puts "#{type}_ written"
            Dir.data("#{type}_output.html")
          else
            "#{type[0..-6]}output.html"
          end
          File.write(output_file, p['output'])
          puts "#{output_file} written"
          "seed success"
        end
      end
    end

    r.get "cp_other_dev" do
      wiki("dev").cp_other_dev
      "dev5 from the other machine copied. proceed with care"
    end

    r.get "write_extract" do
      fat = wiki("fat")
      stats = fat.write_extract(fat.add_tiddlers)
      `open #{stats[0]}`
      "#{stats}<p>Thank you for your extraction"
    end
  end
end
