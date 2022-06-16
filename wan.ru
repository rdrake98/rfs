require './wany'
require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '/public/*', :headers => :any, :methods => [:get, :post]
  end
end
run Wany.app
