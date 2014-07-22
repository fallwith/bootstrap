%w{active_support/all interactive_editor}.each do |gem|
  begin
    require gem
  rescue LoadError => e
    puts "#{e.message}"
  end
end
