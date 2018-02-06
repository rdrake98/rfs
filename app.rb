require 'roda'
require 'splitter'

$fat = Splitter.fat
puts $fat.edition

class App < Roda
  route do |r|
    r.on "public" do
      r.post "save_tiddler" do
        message = "Received #{r.params['name']}"
        puts message
        message
      end
    end

    r.get "local" do
      puts $fat['MainMenu'].content
      "local only"
    end
  end
end
