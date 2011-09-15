require 'test/unit'
require 'rubygems'
require 'active_record'
require 'active_support'
#require 'active_support/multibyte'
#require 'find_by_param'
require File.join(File.dirname(__FILE__), '../lib/find_by_param.rb')
class ActiveRecord::Base
  class_attribute :permalink_options
  self.permalink_options = {:param => :id}
end
ActiveRecord::Base.send(:include, Railslove::Plugins::FindByParam)

ActiveRecord::Base.establish_connection({
    'adapter' => 'sqlite3',
    'database' => ':memory:'
  })
load(File.join(File.dirname(__FILE__), 'schema.rb'))

