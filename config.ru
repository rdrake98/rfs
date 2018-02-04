require './app'
require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '/public/*', :headers => :any, :methods => [:get, :post]
  end
end
run App.freeze.app
