#!/usr/bin/env ruby

class ObjCClass
	def initialize name
		@objc_name = name
		@objc_superclass_name = :NSObject
		@objc_ivars = {}
		@objc_frameworks = []
		@objc_imports = []
	end
	
	def subclass_of x
		@objc_superclass_name = x
	end
	
	def ivar name, type = nil, *options
		@objc_ivars[name] = ObjCIvar.new name, type || :id, options
	end
	
	def framework x
		@objc_frameworks << x unless @objc_frameworks.include? x
	end

	def import x
		@objc_imports << x unless @objc_imports.include? x
	end
	
	def method_missing name, type = nil, *options
		ivar name, type, *options
	end
	
	attr_reader :objc_name, :objc_ivars, :objc_frameworks, :objc_imports, :objc_superclass_name
end

class ObjCIvarGetterNameOption
	def initialize name
		@name = name
	end
	
	attr_reader :name
end

class ObjCIvar
	def initialize name, type, options
		@name = name
		@objc_type = type
		@options = options
	end
	
	attr_reader :name, :objc_type, :options
end

OBJC_CLASSES = {}

def objc_class name, &block
	x = ObjCClass.new(name)
	OBJC_CLASSES[name] = x
	x.instance_eval(&block)
	x
end
