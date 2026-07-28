# Shared by work.fish and sandbox_sync.fish (autoloaded by name).
function __work_project_file --description 'Find project.json at or above a dir (within ~/projects)'
    set -l dir $argv[1]
    while string match -q "$HOME/projects/*" -- $dir
        if test -f $dir/project.json
            echo $dir/project.json
            return 0
        end
        set dir (dirname $dir)
    end
    return 1
end
