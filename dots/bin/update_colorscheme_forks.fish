#!/usr/bin/env fish

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
    e-ink-colorscheme/e-ink.nvim \
    rebelot/kanagawa.nvim \
    savq/melange-nvim \
    bluz71/vim-nightfly-colors \
    xiantang/darcula-dark.nvim \
    navarasu/onedark.nvim \
    zaki/zazen \
    r1cardohj/zzz.vim \
    wesenseged/stone.nvim \
    github-main-user/lytmode.nvim \
    Ronxvier/ymir.nvim \
    kaiuri/juliana.nvim \
    meccin/shizukana.nvim \
    mitch1000/backpack.nvim \
    vyrx-dev/void.nvim \
    nkxxll/ghostty-default-style-dark.nvim \
    KijitoraFinch/nanode.nvim \
    caelyreth/myrrh.nvim \
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
    builtbyleo/oc-2.nvim \
    kcayme/bearded-arc.nvim \
    omacom-io/lumon.nvim \
    dgrco/hearthlight.nvim \
    ankushbhagats/pastel.nvim \
    mohseenrm/brutus \
    vimcolorschemes/olive-crt.nvim \
    gillisc/cynosure.nvim \
    aejkatappaja/sora \
    sudoscrawl/midnight.nvim \
    thorstenrhau/token \
    terkelg/north-sea.nvim \
    davidklassen/mote \
    pisgahk/muted.nvim \
    ember-theme/nvim \
    pankvitek/bonbon.nvim \
    anhari/zorn.nvim \
    zitrocode/carvion.nvim \
    xpac27/humdrum.vim \
    nopangel/nimmy.vim \
    jamesgadoury/neon-ghost-theme \
    metalelf0/kintsugi-nvim \
    jpwol/thorn.nvim \
    initsyscall/themeinitnvim \
    web-dev-codi/cybersynth.nvim \
    miladggg/neonwave.nvim \
    tickloop/solaris.nvim \
    danfry1/rime \
    ogswag/valve-olive.nvim \
    boningmaple/mac-clear \
    shiraied/wolf359_nvim_rust_theme \
    oahlen/aurora.nvim \
    nyvyme/naysayer.nvim \
    al3rez/darktooth.nvim \
    r1cardohj/citylights.vim \
    psteven5/winterland.vim \
    rockorager/radix.nvim \
    art220/dancheong.nvim \
    WTFox/luna.nvim

set -l successes
set -l auto_fixed
set -l orphaned
set -l failures

# a fork's name cannot be derived from its source repo. observed in the list
# above: a collision suffix (two distinct `owner/nvim` repos, so the second
# fork became `nvim-1`), a hand-renamed fork, and several upstreams that were
# renamed or transferred while the fork kept the old name. guessing `basename`
# aims the second repo of a colliding pair at the FIRST repo's fork, which
# syncs fine and is counted as a success while the real fork silently goes
# stale -- so ask the API for the mapping once, then resolve locally.
#
# `gh repo list` with no argument uses the authenticated user, and
# nameWithOwner carries the owner, so no GitHub handle is hardcoded here.
set -l my_full
set -l my_names
set -l my_forked
set -l my_parents
for row in (gh repo list --limit 1000 --json nameWithOwner,name,isFork,parent \
        --jq '.[] | "\(.nameWithOwner)\t\(.name)\t\(.isFork)\t\(if .parent then .parent.owner.login + "/" + .parent.name else "-" end)"')
    set -l parts (string split \t -- $row)
    set -a my_full $parts[1]
    set -a my_names $parts[2]
    set -a my_forked $parts[3]
    set -a my_parents (string lower -- $parts[4])
end

if test (count $my_full) -eq 0
    echo "Error: listed no repos -- is gh authenticated? try `gh auth status`" >&2
    exit 1
end

for repo in $repos
    set -l name (basename $repo)
    set -l repo_lc (string lower -- $repo)

    echo "=== $repo ==="

    # prefer a fork whose parent is this exact repo; fall back to a repo of
    # mine sharing the name, which is what a renamed or deleted upstream
    # leaves behind (the parent link no longer points at the listed repo)
    set -l candidates
    for i in (seq (count $my_full))
        if test "$my_parents[$i]" = "$repo_lc"
            set -a candidates $i
        end
    end

    set -l fork_idx
    for i in $candidates
        if test (string lower -- $my_names[$i]) = (string lower -- $name)
            set fork_idx $i
            break
        end
    end
    if test -z "$fork_idx"; and test (count $candidates) -gt 0
        set fork_idx $candidates[1]
    end
    if test -z "$fork_idx"
        set fork_idx (contains -i -- (string lower -- $name) (string lower -- $my_names))
        if test -n "$fork_idx"
            echo "  -> Upstream no longer parents the fork; using $my_full[$fork_idx] by name"
        end
    end

    set -l fork
    if test -n "$fork_idx"
        # GitHub promotes a fork to a root repo when its upstream is deleted,
        # so there is no source left to sync from
        if test "$my_forked[$fork_idx]" = false
            echo "  -> $my_full[$fork_idx] has no upstream; the source repo is gone"
            set -a orphaned "$repo | $my_full[$fork_idx] is a root repo now, nothing to sync"
            continue
        end
        set fork $my_full[$fork_idx]
    else
        # nothing to reuse, so create the fork with an explicit name rather
        # than letting GitHub silently append a collision suffix
        set -l fork_name $name
        if contains -- (string lower -- $fork_name) (string lower -- $my_names)
            set fork_name (string replace -a / - -- $repo)
        end
        echo "  -> No fork yet, creating $fork_name..."
        if not gh repo fork $repo --clone=false --fork-name $fork_name 2>&1
            set -a failures "$repo | could not create a fork named $fork_name"
            continue
        end
        # only this branch needs the account name, to address the new fork
        set -l login (gh api user --jq .login 2>/dev/null)
        if test -z "$login"
            set -a failures "$repo | forked, but could not resolve the account name to sync it"
            continue
        end
        set fork $login/$fork_name
        set -a my_full $fork
        set -a my_names $fork_name
        set -a my_forked true
        set -a my_parents $repo_lc
    end

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
        echo "  -> $fork no longer resolves, needs manual delete."
        set -a failures "$repo | fork gone or renamed, find and delete: https://github.com/$fork"
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
            echo "$sync_out"
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
echo "  Orphaned:   "(count $orphaned)
echo "  Failed:     "(count $failures)
echo ""

if test (count $auto_fixed) -gt 0
    echo "--- Auto-fixed ---"
    for entry in $auto_fixed
        echo "  + $entry"
    end
    echo ""
end

if test (count $orphaned) -gt 0
    echo "--- Orphaned (upstream gone; drop from the list or keep as an archive) ---"
    for entry in $orphaned
        echo "  ? $entry"
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
