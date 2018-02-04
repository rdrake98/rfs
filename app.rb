require 'roda'
require 'base'

class App < Roda
  route do |r|
    r.on "public" do
      @greeting = Time.fov_str
      r.get "world" do
        "#{@greeting} world from cors!"
      end
      r.post "post" do
        message = "On #{@greeting} we received #{r.params['name']}"
        puts message
        message
      end
    end

    r.get "local" do
      "local only"
    end
  end
end
