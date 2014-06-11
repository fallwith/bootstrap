require 'irb/completion'
require 'irb/ext/save-history'
require 'interactive_editor'
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"
IRB.conf[:SAVE_HISTORY] = 1000
