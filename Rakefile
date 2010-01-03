require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the find_by_param plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the find_by_param plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FindByParam'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  gem 'jeweler', '>= 0.11.0'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name        = "find_by_param"
    s.summary     = "Rails plugin to handle permalink values"
    s.email       = "michael@derbumi.com"
    s.homepage    = "http://github.com/bumi/find_by_param"
    s.description = "find_by_param is a nice and easy way to handle " +
                    "permalinks and dealing with searching for to_param values"
    s.authors = ["Michael Bumann", "Gregor Schmidt"]
    s.add_dependency('activerecord', '>= 2.3')

    s.add_development_dependency('sqlite3-ruby')
    s.add_development_dependency('jeweler', '>= 0.11.0')
    s.add_development_dependency('rake')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler --version '>= 0.11.0'"
  exit(1)
end
