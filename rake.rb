# rake.rb

if ARGV[0]
  require './test/quick_fat.rb'
else
  Dir.glob('./test/test*.rb')[1..-1].each { |file| require file }
end