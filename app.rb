require 'roda'
require 'splitter'

class App < Roda
  puts "restarting rfs"
  Wikis = {}

  def basic?(type); type.size == 3; end

  def load_basic(type)
    basic?(type) ? (type == "fat" ? Splitter.fat : Splitter.dev) : nil
  end

  def wiki(type, any_wiki=true)
    Wikis[type] ||
    (wiki = load_basic(type) || any_wiki && Splitter.new(type)) &&
    Wikis[type] = wiki
  end

  def reload(type)
    puts "reloading #{type} into server from file"
    Wikis[type] = load_basic(type) || Splitter.new(type)
  end

  def respond(p, &block)
    response = {}
    type, browser_edition = p['type'], p['edition']
    if clash = (wiki = wiki type).check_file_edition(browser_edition)
      response["clash"] = clash.split(",")[0]
    else
      wiki = reload(type) if basic?(type) && wiki.edition != browser_edition
      wiki.add_tiddlers(p['changes'])
      block.call wiki, response
    end
    response.to_json
  end

  route do |r|
    r.on "public" do
      r.post "search" do
        p = r.params
        name, regex, caseSensitive = p['name'], p['regex'], p['case']
        puts "searching for '#{name}' using '#{regex}' in #{p['type']}"
        respond(p) do | wiki, response |
          response["titles"] = wiki.search(regex, name, caseSensitive)
        end
      end

      r.post "link" do
        p = r.params
        title, name, target = p['title'], p['name'], p['target']
        target = nil if target == ""
        insert = target ? ' with ' + target : ''
        puts "#{p['action']} '#{name}'#{insert} in #{title} in #{p['type']}"
        respond(p) do | wiki, response |
          unlink = p['unlink'] == "true"
          overlink = p['overlink'] == "true"
          new_text, replacer = wiki[title].link(name, target, unlink, overlink)
          response["newText"] = new_text
          response["replacer"] = replacer
        end
      end

      r.post "bulk_change" do
        p = r.params
        title = p['title']
        puts "bulk change based on #{title} in #{p['type']}"
        respond(p) do | wiki, response |
          response["changes"] = wiki[title].bulk_change
        end
      end

      r.post "save" do
        p = r.params
        type, edition, changes = p['type'], p['edition'], p['changes']
        wiki = wiki(type)
        wiki.check_file_edition(edition, changes) || # clash if not nil
          wiki.save(edition, changes) || reload(type).save(edition, changes)
      end

      r.post "change_tiddler" do
        p = r.params
        type = p['type']
        message = "#{p['title']} #{p['action']} in #{type}"
        puts message
        wiki(type, nil)&.add_changes(p['changes'], p['shared'] == "true")
        message
      end

      r.post "order_change" do
        p = r.params
        wiki(p['type'], nil)&.order_change(p['open'])
        ""
      end

      r.post "other_changes" do
        p = r.params
        from_self = p['from_self'].true?
        fat = wiki("fat")
        fat = reload("fat") if fat.edition != Splitter.fat_edition
        machine = from_self ? 'this machine' : 'm' + fat.other_host
        puts "adding changes from #{machine} to fat on startup"
        fat.other_changes(from_self)
      end

      r.post "seed" do
        p = r.params
        type = p['type']
        # javascript test: type.length == 3 || type.endsWith("fat_.html")
        if type == "fat" && wiki("fat").check_file_edition(p['edition'])
          "version clash"
        else
          output_file = if basic?(type)
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
