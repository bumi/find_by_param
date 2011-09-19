begin
  $KCODE = 'u' if RUBY_VERSION < '1.9'

  require 'rubygems'
  require 'active_support'
rescue LoadError
end

module Railslove
  module Plugins
    module FindByParam
      def self.enable # :nodoc:
        return if ActiveRecord::Base.kind_of?(self::ClassMethods)

        ActiveRecord::Base.class_eval do
          if respond_to? :class_attribute
            class_attribute :permalink_options
          else
            class_inheritable_accessor :permalink_options
          end

          self.permalink_options = {:param => :id}

          #default finders these are overwritten if you use make_permalink in
          # your model
          def self.find_by_param(value,args={}) # :nodoc:
            find_by_id(value,args)
          end
          def self.find_by_param!(value,args={}) # :nodoc:
            find(value,args)
          end
        end
        ActiveRecord::Base.extend(self::ClassMethods)
      end

      module ClassMethods


=begin rdoc

This method initializes find_by_param

  class Post < ActiveRecord::Base
    make_permalink :with => :title, :prepend_id => true
  end

The only required parameter, is <tt>:with</tt>.

If you want to use a non URL-save attribute as permalink your model should have a permalink-column to save the escaped permalink value. This field is then used for search.

If your you can just say make_permalink :with => :login and you're done.

You can use for example User.find_by_param(params[:id], args) to find the user by the defined permalink.

== Available options

<tt>:with</tt>:: (required) The attribute that should be used as permalink
<tt>:field</tt>:: The name of your permalink column. make_permalink first checks if there is a column, default is 'permalink'.
<tt>:prepend_id</tt>:: [true|false] Do you want to prepend the ID to the permalink? for URLs like: posts/123-my-post-title - find_by_param uses the ID column to search, default is false.
<tt>:param_size</tt>:: [Number] Desired maximum size of the permalink, default is 50.
<tt>:escape</tt>:: [true|false] Do you want to escape the permalink value? (strip chars like öä?&) - actually you must do that, default is true.
<tt>:validate</tt>:: [true|false] Don't validate the :with field - set this to false if you validate it on your own, default is true.
<tt>:forbidden</tt>:: [Regexp|String|Array of Strings] Define which values should be forbidden. This is useful when combining user defined values to generate permalinks in combination with restful routing. <b>Make sure, especially in the case of a Regexp argument, that values may become valid by adding or incrementing a trailing integer.</b>
=end
        def make_permalink(options={})
          options[:field] ||= "permalink"
          options[:param] = options[:with] # :with => :login - but if we have a spcific permalink column we need to set :param to the name of that column
          options[:escape] ||= true
          options[:prepend_id] ||= false
          options[:param_size] ||= 50
          options[:validate] = true if options[:validate].nil?

          # validate if there is something we can use as param. you can overwrite the validate_param_is_not_blank method to customize the validation and the error messge.
          if !options[:prepend_id] || !options[:validate]
            validate :validate_param_is_not_blank
          end

          if forbidden = options.delete(:forbidden)
            if forbidden.is_a? Regexp
              options[:forbidden_match] = forbidden
            else
              options[:forbidden_strings] = Array(forbidden).map(&:to_s)
            end
          end

          if self.column_names.include?(options[:field].to_s)
            options[:param] = options[:field]
            before_save :save_permalink
          end

          self.permalink_options = options
          extend Railslove::Plugins::FindByParam::SingletonMethods
          include Railslove::Plugins::FindByParam::InstanceMethods
        rescue ActiveRecord::ActiveRecordError
          puts "[find_by_param error] database not available?"
        end
      end

      module SingletonMethods

=begin rdoc

Search for an object by the defined permalink column. Similar to
+find_by_login+. Returns +nil+ if nothing is found. Accepts an options hash as
second parameter which is passed on to the rails finder.
=end
        def find_by_param(value, args={})
          if permalink_options[:prepend_id]
            param = "id"
            value = value.to_i
          else
            param = permalink_options[:param]
          end
          self.send("find_by_#{param}".to_sym, value, args)
        end

=begin rdoc

Like +find_by_param+ but raises an <tt>ActiveRecord::RecordNotFound</tt> error
if nothing is found - similar to find().

Accepts an options hash as second parameter which is passed on to the rails
finder.
=end
        def find_by_param!(value, args={})
          param = permalink_options[:param]
          obj = find_by_param(value, args)
          raise ::ActiveRecord::RecordNotFound unless obj
          obj
        end
      end

      module InstanceMethods
        def to_param
          value = self.send(permalink_options[:param]).dup.to_s.downcase rescue ""
          ''.tap do |param|
            if value.blank?
              param << id.to_s
            else
              param << "#{id}-" if permalink_options[:prepend_id]
              param << escape_and_truncate_permalink(value)
            end
          end
        end

        protected

        def save_permalink
          return unless self.class.column_names.include?(permalink_options[:field].to_s)
          counter = 0
          base_value = escape_and_truncate_permalink(send(permalink_options[:with])).downcase
          permalink_value = base_value.to_s

          conditions = ["#{self.class.table_name}.#{permalink_options[:field]} = ?", permalink_value]
          unless new_record?
            conditions.first << " and #{self.class.table_name}.#{self.class.primary_key} != ?"
            conditions       << self.send(self.class.primary_key.to_sym)
          end
          while is_forbidden?(permalink_value) or
                self.class.count(:all, :conditions => conditions) > 0
            counter += 1
            permalink_value = "#{base_value}-#{counter}"

            if permalink_value.size > permalink_options[:param_size]
              length = permalink_options[:param_size] - counter.to_s.size - 2
              truncated_base = base_value[0..length]
              permalink_value = "#{truncated_base}-#{counter}"
            end

            conditions[1] = permalink_value
          end
          write_attribute(permalink_options[:field], permalink_value)
          true
        end

        def validate_param_is_not_blank
          if self.escape_and_truncate_permalink(self.send(permalink_options[:with])).blank?
            errors.add(permalink_options[:with],
                       "must have at least one non special character (a-z 0-9)")
          end
        end

        def escape_permalink(value)
          value.to_s.parameterize
        end

        def is_forbidden?(permalink_value)
          is_forbidden_string?(permalink_value) ||
            matches_forbidden_regexp?(permalink_value)
        end

        def is_forbidden_string?(permalink_value)
          permalink_options[:forbidden_strings] &&
            permalink_options[:forbidden_strings].include?(permalink_value)
        end

        def matches_forbidden_regexp?(permalink_value)
          permalink_options[:forbidden_match] &&
            permalink_options[:forbidden_match] =~ permalink_value
        end

        def escape_and_truncate_permalink(value)
          p = self.escape_permalink(value)[0...self.permalink_options[:param_size]]
          p.ends_with?('-') ? p.chop : p
        end
      end

    end
  end
end

if defined?(ActiveRecord)
  Railslove::Plugins::FindByParam.enable
end
