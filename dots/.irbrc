# frozen_string_literal: true

# Helper Usage Instructions:
#
# irb> echo off
#   - This will disable Irb's echoing the last expression's value
#
# irb> echo on
#   - This will restore Irb's echoing (return to the default behavior)
#
# irb> pbcopy myvar
#   - This will copy the contents of the given value onto the macOS clipboard
#
# irb> myvar = pbpaste
#   - This will paste from the macOS clipboard into a variable
#
# irb> info MYCONSTANT
#   - Get source location info for the given constant
#
# irb> info 'MyClass.method'
#   - Get source location info for the given class method
#
# irb> info 'MyClass#method'
#   - Get source location info for the given instance method

require 'irb/completion'
begin
  require 'interactive_editor'
rescue LoadError
  puts "Couldn't load interactive_editor for this session"
end

IRB.conf[:AUTO_INDENT] = true
IRB.conf[:BACK_TRACE_LIMIT] = 75
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:USE_AUTOCOMPLETE] = true
# use the reline default if you prefer the fancy autocomplete pop-up ui
IRB.conf[:USE_READLINE] = true

COLON = ':'

def off
  false
end

def on
  true
end

def echo(on = true) # rubocop:disable Style/OptionalBooleanParameter
  conf.echo = on
end

def flush_sidekiq
  Sidekiq.redis(&:flushdb)
end

def pbcopy(text)
  `echo "#{text}"|pbcopy`
end

def pbpaste
  `pbpaste`.chomp
end

def info(object)
  if object.to_s =~ /([^.#]+)([.#])(\w+)/
    klass = Object.const_get(constant_as_string_or_symbol) rescue nil # rubocop:disable Style/RescueModifier
    delimiter = Regexp.last_match(2)
    method = Regexp.last_match(3)

    klass_method = delimiter == '.' ? :method : :instance_method
    return klass.send(klass_method, method).source_location.join(COLON) if klass
  end

  return Object.const_source_location(object.to_s).join(COLON) if constant?(object.to_s)

  puts "No info known about #{object}"
end

def constant?(constant_as_string_or_symbol)
  return false if constant_as_string_or_symbol.to_s.match?(/[.:]/)

  Object.const_defined?(object.to_s)
rescue NameError
  false
end
