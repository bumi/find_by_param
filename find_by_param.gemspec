$:.unshift File.expand_path('../lib', __FILE__)
require 'find_by_param/version'

Gem::Specification.new do |s|
  s.name        = "find_by_param"
  s.version     = Railslove::Plugins::FindByParam::VERSION
  s.authors     = ["Michael Bumann", "Gregor Schmidt"]
  s.email       = "michael@railslove.com"
  s.homepage    = "http://github.com/bumi/find_by_param"
  s.summary     = "Rails plugin to handle permalink values"
  s.description = "find_by_param is a nice and easy way to handle " +
                  "permalinks and dealing with searching for to_param values"

  s.files = Dir.glob("lib/**/*.rb")
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  # Currently supports Rails 2.3, 3.0, and 3.1, but I cannot express that using
  # Gem dependencies.
  s.add_dependency('activerecord')
  s.add_dependency('activesupport')

  s.add_development_dependency('sqlite3-ruby')
  s.add_development_dependency('rake')
end

