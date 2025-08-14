function pngit --description 'Convert any image to PNG format'
  if test (count $argv) -eq 0
    echo "Usage: pngit <image_file>"
    return 1
  end

  set file $argv[1]
  mogrify -format png $file
  rm -f $file
end
