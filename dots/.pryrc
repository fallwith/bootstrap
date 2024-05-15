# see https://github.com/pry/pry/wiki/Customization-and-configuration
# require "awesome_print"
# AwesomePrint.pry!

# Pry.editor = "nvim"

# if !Object.const_defined?('Pry::HAS_SAFE_LEVEL') ||
#   (Object.const_defined?('Pry::HAS_SAFE_LEVEL') && Pry::HAS_SAFE_LEVEL)
#   $SAFE ||= 1
# end

#Pry.config.prompt_name = "\xF0\x9F\x90\xA8  "
#Pry.print = proc { |output, value| output.puts value.ai(indent: 2) }

# tips
# ----
# disable automatic printing of the result by appending a semicolon to the line before hitting enter
# .clear = clear the console display
# wtf? = give stack trace info - add additional question marks for additional verbosity
# pry-backtrace = output the stack trace for the classes/modules that led up to the current point
# show-source = show the source code for the current object in scope
# disable-pry = completely disable pry and return unfettered control to the ruby app (removes all future breakpoints)
# cd <obj> - jump into the given object. then call 'ls' or defined methods directly
# ls - list the methods, constants, and variables available for the current object in scope (after 'cd')
# edit <obj> - edit the source for the given object
# .<cmd> - run the given shell command
# play -l 123 - replay the code from the given line. see 'play --help' for other play functionality
# cat --ex - show the lines surrounding the location of the last exception
