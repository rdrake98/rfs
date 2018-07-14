require 'roda'
require 'splitter'
# require 'dd'

$wikis = {
  fat: Splitter.fat,
  dev: Splitter.dev
}
puts $wikis[:fat].edition
puts $wikis[:dev].edition

class App < Roda
  route do |r|
    r.on "public" do
      r.post "change_tiddler" do
        p = r.params
        wiki_name = p['wiki'].to_sym
        message = "#{p['title']} #{p['action']} in #{wiki_name}"
        puts message
        wiki = $wikis[wiki_name]
        wiki.add_changes(p['changes'])
        message
      end
    end

    r.get "local" do
      puts $wikis[:fat]['rfs'].content
      "local only"
    end

    r.get "try_save" do
      # byebug
      $wikis[:dev].try_save
      "save done"
    end

    r.get "try_backup" do
      $wikis[:dev].try_backup
      "backup done"
    end
  end
end
