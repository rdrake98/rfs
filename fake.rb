# fake.rb

require 'base'

if ARGV[0] == 'e'
  require './test/test_externals.rb'
elsif ARGV[0]
  require './test/quick_fat.rb'
else
  Dir.glob('./test/test*.rb')[2..-1].each { |file| require file }
end
