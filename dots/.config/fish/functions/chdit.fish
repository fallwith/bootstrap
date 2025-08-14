function chdit --description 'Convert cue/gdi/iso files to chd format'
  if test (count $argv) -eq 0
    echo "Usage: chdit <file.cue|file.gdi|file.iso>"
    return 1
  end

  set cue_file $argv[1]
  set chd_file (string replace -r '\.(cue|gdi|iso)$' '.chd' $cue_file)
  chdman createcd -i $cue_file -o $chd_file
end
