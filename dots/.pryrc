# see https://github.com/pry/pry/wiki/Customization-and-configuration

%w{active_support/all interactive_editor}.each do |gem|
  begin
    require gem
  rescue LoadError => e
    puts "#{e.message}"
  end
end

Pry.editor = 'vim'
Pry.config.prompt_name = "\xF0\x9F\x90\xA8  "

# tips
# ----
# disable automatic printing of the result by appending a semicolon to the line before hitting enter
# .clear = clear the console display
# wtf? = give stack trace info - add additional question marks for additional verbosity
# pry-backtrace = output the stack trace for the classes/modules that led up to the current point
# show-source = show the source code for where the current binding.pry is located
