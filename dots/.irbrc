require 'irb/completion'
require 'irb/ext/save-history'
begin
  require 'interactive_editor'
rescue LoadError
  puts "Couldn't load interactive_editor for this session"
end
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"
IRB.conf[:SAVE_HISTORY] = 1000
