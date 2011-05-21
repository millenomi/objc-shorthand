#!/usr/bin/env ruby

require 'rubygems'
require 'mustache'
require 'objc_shorthand'

# -------------

class ObjCClassTemplate < Mustache	
	attr_accessor :cls, :shorthand_file
	
	def initialize cls, shorthand_file
		@cls = cls
		@shorthand_file = shorthand_file
	end
	
	def ivars
		@cls.objc_ivars.map { |name, x| ObjCIvarTemplate.new(x) }
	end
	
	def ivars_with_properties; ivars; end
	def ivars_without_properties; []; end
	
	def ivars_with_properties_without_ro
		ivars_with_properties.select { |x| not x.ivar.options.include? :ro }
	end
	
	def ivars_without_properties_or_with_ro
		ivars_with_properties.select { |x| x.ivar.options.include? :ro }
	end
	
	def frameworks
		@cls.objc_frameworks
	end
	
	def imports
		@cls.objc_imports
	end
	
	def class_name
		@cls.objc_name
	end
	
	def superclass_name
		@cls.objc_superclass_name
	end
	
	def needs_legacy
		true
	end
end

class ObjCIvarTemplate
	def initialize ivar
		@ivar = ivar
	end
	
	attr_reader :ivar
	
	def ivar_type
		t = ivar.objc_type
		t = "NSString*" if t == :str
		t = "NSInteger" if t == :int
		t = "NSUInteger" if t == :uint
		t = "BOOL" if t == :bool
		t = "#{t}*" if t.kind_of? Symbol and t != :id and t != :Class
		t
	end
	
	def is_object_type
		t = ivar.objc_type
		return true if ivar.options.include?(:object)
		return false if (t == :int or t == :uint or t == :bool)
		return true if t.kind_of?(Symbol)
		
		(t =~ /^\s*id\s*(<|$)/) != nil
	end
	
	def ivar_name
		"#{ivar.name}_"
	end
	
	def outlet_marker
		'IBOutlet' if ivar.options.include? :outlet
	end
	
	def memory_management_marker
		if is_object_type
			if ivar.options.include? :retain
				'retain'
			elsif ivar.options.include? :copy
				'copy'
			elsif ivar.options.include? :assign
				'assign'
			elsif ivar.name.to_s == 'delegate' or ivar.name.to_s =~ /Delegate$/ and not ivar.options.include? :ro
				'assign'
			elsif not ivar.options.include? :ro
				'retain'
			end
		end
	end
	
	def property_modifiers
		s = []
		
		marker = memory_management_marker
		s << marker if marker
		
		s << 'nonatomic' unless ivar.options.include? :atomic
		
		if ivar.options.include? :ro
			s << 'readonly'
		end
		
		getter_name = ivar.options.select { |x| x.kind_of? ObjCIvarGetterNameOption }[0]
		if getter_name
			s << "getter = #{getter_name.name}"
		end
		
		return "(#{s.join ','})"
	end
	
	def property_name
		ivar.name
	end
	
	def capitalized_property_name
		p = property_name.to_s.dup
		p[0,1] = p[0,1].upcase
		p
	end
	
	def will_set
		ivar.options.include? :will_set
	end
	
	def did_set
		ivar.options.include? :did_set
	end
	
	def will_get
		ivar.options.include? :will_get
	end
	
	def needs_explicit_setter
		will_set || did_set
	end
	
	def needs_explicit_getter
		will_get
	end
	
	def is_assign
		marker = memory_management_marker
		marker != 'retain' and marker != 'copy'
	end
	
	def memory_management_call
		memory_management_marker
	end
	
end

# -------------

load ARGV[0]

OBJC_CLASSES.each do |name, cls|
	File.open("#{name}.h", 'w') do |io|
		t = ObjCClassTemplate.new(cls, File.expand_path(ARGV[0]))
		t.template_file = File.join(File.dirname(__FILE__), 'objc_header.mustache')
		
		io << t.render
	end
	
	File.open("#{name}.m", 'w') do |io|
		t = ObjCClassTemplate.new(cls, File.expand_path(ARGV[0]))
		t.template_file = File.join(File.dirname(__FILE__), 'objc_implementation.mustache')
		
		io << t.render
	end
end
