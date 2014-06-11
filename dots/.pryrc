begin
  require 'active_support/all'
  require 'interactive_editor'
rescue LoadError => e
  puts "#{e.message}"
end
