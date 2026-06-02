function gpg-warm --description 'Check if the git signing key passphrase is cached; prompt to unlock it if not'
    set -l key (git config --get user.signingkey)
    if test -z "$key"
        echo "no user.signingkey configured in git - nothing to warm" >&2
        return 1
    end

    # Probe with pinentry forbidden: cached -> signs silently, not cached -> errors (no prompt).
    if echo warm | gpg --batch --no-tty --pinentry-mode error -u $key --sign -o /dev/null 2>/dev/null
        echo "gpg key $key already cached - no prompt this session"
        return 0
    end

    echo "gpg key $key not cached - unlocking now so git won't ambush you later..."
    if echo warm | gpg --no-tty -u $key --sign -o /dev/null 2>/dev/null
        echo "gpg key $key cached"
        return 0
    else
        echo "gpg key $key still not cached (unlock cancelled or failed)" >&2
        return 1
    end
end
