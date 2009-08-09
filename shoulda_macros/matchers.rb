# this nesting is actually a bit stupid :)
module Railslove
  module Plugins
    module FindByParam
      module Shoulda
        module Matchers
          def validate_find_by_param_options(options)
            FindByParamMatcher.new(options)
          end
          class FindByParamMatcher
            def initialize(options)
              @expected_options = options
            end
  
            def matches?(klass)
              @klass = klass
              valid_permalink_options? && responds_to_find_by_param_class_methods? && responds_to_find_by_param_instance_methods?
            end

            def description
              "have valid find_by_pram_configuration"
            end
  
            def failure_message
              "invalid find_by_param configuration: expected: #{@expected_options.inspect} got: #{@klass.permalink_options.inspect}"
            end
  
            protected
              def valid_permalink_options?
                @expected_options == @klass.permalink_options
              end
    
              def responds_to_find_by_param_class_methods?
                %w{make_permalink find_by_param find_by_param!}.all? do |method|
                  @klass.respond_to?(method)
                end 
              end
    
              def responds_to_find_by_param_instance_methods?
                %w{escape_permalink}.all? do |method|
                  @klass.new.respond_to?(method)
                end 
              end
          end
        end
      end
    end
  end
end