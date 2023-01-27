# frozen_string_literal: true

require 'irb/completion'
require 'irb/ext/save-history'
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

def off
  false
end

def on
  true
end

def echo(on = true)
  conf.echo = on
end
