# fake.rb

if ARGV[0] == 'e'
  require './test/test_externals.rb'
elsif ARGV[0]
  require './test/quick_fat.rb'
else
  Dir.glob('./test/test*.rb')[1..-2].each { |file| require file }
end
