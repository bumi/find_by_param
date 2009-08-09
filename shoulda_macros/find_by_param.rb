require File.join(File.dirname(__FILE__), 'matchers')
# this is experimental. My first try to write a shoulda matcher
module Railslove
  module Plugins
    module FindByParam
      module Shoulda
        include Matchers
        
        def should_make_permalink(options = {})
          klass = self.name.gsub(/Test$/, '').constantize

          options[:field] ||= "permalink"
          options[:param] = options[:with]
          options[:escape] ||= true
          options[:prepend_id] ||= false
          options[:param_size] ||= 50
          options[:validate] ||= true
          if klass.column_names.include?(options[:field].to_s)
            options[:param] = options[:field]
          end

          matcher = validate_find_by_param_options(options)

          should matcher.description do 
            assert_accepts(matcher, klass)
          end
        end
      end
    end
  end
end
class Test::Unit::TestCase
  extend Railslove::Plugins::FindByParam::Shoulda
end