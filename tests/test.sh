#!/usr/bin/env bash
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/sloctl" <<'MOCK'
#!/bin/sh
[ "$*" = 'config current-context' ] || exit 2
[ "${MOCK_FAIL-}" != 1 ] || exit 1
printf '%s\n' "${MOCK_CONTEXT-}"
MOCK
chmod +x "$tmp/sloctl"
export PATH="$tmp:$PATH" PLUGIN="$root/sloctl-context.plugin.sh"
for shell in bash zsh; do
    command -v "$shell" >/dev/null || { printf 'Missing %s\n' "$shell" >&2; exit 1; }
    "$shell" -c '
        source "$PLUGIN"
        export MOCK_CONTEXT=first
        [ "$(sloctl_context)" = "(slo:first)" ] || exit 1
        MOCK_CONTEXT=second
        [ "$(sloctl_context)" = "(slo:second)" ] || exit 1
        SLOCTL_CONTEXT_PREFIX="[" SLOCTL_CONTEXT_SUFFIX="]"
        [ "$(sloctl_context)" = "[second]" ] || exit 1
        MOCK_CONTEXT=""
        [ -z "$(sloctl_context)" ] || exit 1
        MOCK_FAIL=1
        [ -z "$(sloctl_context)" ] || exit 1
    '
done
zsh -c '
    source "$PLUGIN"
    export MOCK_CONTEXT="name%F{red}"
    [ "$(sloctl_context)" = "(slo:name%%F{red})" ] || exit 1
'
printf 'All tests passed.\n'

# Exercise the installed theme when available; no user configuration is loaded.
p10k_theme=${P10K_THEME:-$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme}
if [ -r "$p10k_theme" ]; then
    export P10K_THEME="$p10k_theme" P10K_PLUGIN="$root/sloctl-context-powerlevel10k.zsh"
    zsh -dfi -c '
        source "$P10K_THEME"
        typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true POWERLEVEL9K_INSTANT_PROMPT=off
        typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir prompt_char)
        typeset -ga POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status)
        source "$P10K_PLUGIN"
        source "$P10K_PLUGIN"
        matches=(${(@M)POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS:#sloctl_context})
        (( ${#matches} == 1 )) || exit 1
        export MOCK_CONTEXT=first
        _p9k_precmd
        [[ $RPROMPT == *first* ]] || exit 1
        MOCK_CONTEXT=second
        _p9k_precmd
        [[ $RPROMPT == *second* ]] || exit 1
        MOCK_CONTEXT=""
        _p9k_precmd
        [[ $RPROMPT != *slo:* ]] || exit 1
    '
    printf 'Powerlevel10k integration passed.\n'
fi
