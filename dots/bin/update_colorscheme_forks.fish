#!/usr/bin/env fish

set -l gh_user fallwith

set repos \
    mellow-theme/mellow.nvim \
    sainnhe/gruvbox-material \
    sainnhe/everforest \
    sainnhe/sonokai \
    rose-pine/neovim \
    rmehri01/onenord.nvim \
    sainnhe/edge \
    LuRsT/austere.vim \
    ribru17/bamboo.nvim \
    samharju/serene.nvim \
    EdenEast/nightfox.nvim \
    fxn/vim-monochrome \
    alexxGmZ/e-ink.nvim \
    rebelot/kanagawa.nvim \
    savq/melange-nvim \
    bluz71/vim-nightfly-colors \
    xiantang/darcula-dark.nvim \
    navarasu/onedark.nvim \
    zaki/zazen \
    r1cardohj/zzz.vim \
    wesenseged/stone.nvim \
    github-main-user/lytmode.nvim \
    RonelXavier/ymir.nvim \
    kaiuri/juliana.nvim \
    avuenja/shizukana.nvim \
    mitch1000/backpack.nvim \
    vyrx-dev/void.nvim \
    nkxxll/ghostty-default-style-dark.nvim \
    KijitoraFinch/nanode.nvim \
    utakotoba/myrrh.nvim \
    zanshin/nvim-fourcolor-theme \
    folksoftware/nvim \
    guillermodotn/nvim-earthsong \
    dlvandenberg/stilla.nvim \
    alexpasmantier/hubbamax.nvim \
    eggfriedrice24/eggfriedrice.nvim \
    oskarnurm/koda.nvim \
    MartelleV/kaimandres.nvim \
    maroozm/moegi-neovim \
    ATTron/bebop.nvim \
    Old-Farmer/noctis-nvim \
    wunki/gondolin.nvim \
    NisonChrist/tailwind-theme.nvim \
    bergholmm/cursor-dark.nvim \
    voylin/godot_color_theme \
    aisk/kukishinobu.vim \
    kotsuban/nekomi.nvim \
    waytoopurple/fieldlights.nvim \
    T-b-t-nchos/Aquavium.nvim \
    jakubkarlicek/molokai-nvim \
    Kopihue/one-dark-pro-max \
    kurund/atomic.nvim \
    smit4k/shale.nvim \
    nnavales/paragon \
    ikelaiah/nebula-drift-omega \
    hopsk/tomorrow-night-bright-rstudio.nvim \
    aymenhafeez/doric-themes.nvim \
    bashful-strix/arcana \
    m-mead/eddy.nvim \
    vague-theme/vague.vim \
    ilm-alan/venice.vim \
  marcos-venicius/zenburned \
  0xleodevv/oc-2.nvim

set -l successes
set -l auto_fixed
set -l failures

for repo in $repos
    set -l name (basename $repo)
    set -l fork $gh_user/$name

    echo "=== $repo ==="
    gh repo fork $repo --clone=false 2>&1

    set -l sync_out (gh repo sync $fork 2>&1)
    set -l sync_rc $status

    # --- Diverging changes: auto-retry with --force ---
    if test $sync_rc -ne 0; and string match -q '*diverging changes*' "$sync_out"
        echo "  -> Diverged from upstream, force-syncing..."
        set sync_out (gh repo sync $fork --force 2>&1)
        set sync_rc $status
        if test $sync_rc -eq 0
            if test -n "$sync_out"
                echo "$sync_out"
            else
                echo "up to date"
            end
            set -a auto_fixed "$repo (force-synced diverged fork)"
            continue
        end
        echo "  -> Force-sync failed: $sync_out"
        set -a failures "$repo | diverged (force-sync failed): $sync_out"
        continue
    end

    # --- Repo name mismatch or workflow scope: manual delete and re-run ---
    if test $sync_rc -ne 0
        and string match -q '*Could not resolve to a Repository*' "$sync_out"
        echo "  -> Fork name mismatch, needs manual delete."
        set -a failures "$repo | fork has wrong name, find and delete: https://github.com/$gh_user?tab=repositories&q=$name"
        continue
    end

    if test $sync_rc -ne 0
        and string match -q '*workflow*scope*' "$sync_out"
        echo "  -> Upstream has workflow changes, needs manual delete."
        set -a failures "$repo | delete fork and re-run: https://github.com/$fork/settings"
        continue
    end

    # --- Success ---
    if test $sync_rc -eq 0
        if test -n "$sync_out"
            if test -n "$sync_out"
                echo "$sync_out"
            else
                echo "up to date"
            end
        else
            echo "up to date"
        end
        set -a successes $repo
        continue
    end

    # --- Unrecognized error ---
    echo "  -> Sync failed: $sync_out"
    set -a failures "$repo | $sync_out"
end

# --- Summary Report ---
echo ""
echo "========================================"
echo "  Colorscheme Fork Sync Report"
echo "========================================"
echo ""
echo "  Total:      "(count $repos)
echo "  Succeeded:  "(count $successes)
echo "  Auto-fixed: "(count $auto_fixed)
echo "  Failed:     "(count $failures)
echo ""

if test (count $auto_fixed) -gt 0
    echo "--- Auto-fixed ---"
    for entry in $auto_fixed
        echo "  + $entry"
    end
    echo ""
end

if test (count $failures) -gt 0
    echo "--- Failed (delete fork via link, then re-run) ---"
    for entry in $failures
        echo "  x $entry"
    end
    echo ""
end
