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
        [ "$(sloctl_context)" = "N9:first" ] || exit 1
        MOCK_CONTEXT=second
        [ "$(sloctl_context)" = "N9:second" ] || exit 1
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
    [ "$(sloctl_context)" = "N9:name%%F{red}" ] || exit 1
'
export ZSH_ENTRY="$root/sloctl-context.plugin.zsh"
zsh -dfc '
    source "$ZSH_ENTRY"
    export MOCK_CONTEXT=loader
    [[ $(sloctl_context) == "N9:loader" ]] || exit 1
'

# The Powerlevel10k loader must respect a manually positioned left segment.
export P10K_PLUGIN="$root/sloctl-context-powerlevel10k.zsh"
zsh -dfc '
    typeset -a POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir sloctl_context)
    typeset -a POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status)
    source "$P10K_PLUGIN"
    (( ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[(Ie)sloctl_context]} == 0 )) || exit 1
    p10k() { [[ $1 == segment && $2 == -f && $3 == "#1eb8d1" && $4 == -t && $5 == "%fN%F{#1eb8d1}9:test" ]]; }
    export MOCK_CONTEXT=test
    prompt_sloctl_context || exit 1
    SLOCTL_CONTEXT_PREFIX="custom:"
    p10k() { [[ $5 == "custom:test" ]]; }
    prompt_sloctl_context || exit 1
'
printf 'Bash and zsh checks passed.\n'

# Exercise the installed theme when available; no user configuration is loaded.
p10k_theme=${P10K_THEME:-$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme}
if [ -r "$p10k_theme" ]; then
    export P10K_THEME="$p10k_theme" P10K_PLUGIN="$root/sloctl-context-powerlevel10k.zsh"
    zsh -dfi -c '
        typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true POWERLEVEL9K_INSTANT_PROMPT=off
        source "$P10K_THEME"
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
        [[ $RPROMPT != *N9:* ]] || exit 1
    '
    printf 'Powerlevel10k integration passed.\n'
fi

if command -v fish >/dev/null 2>&1; then
    export FISH_PLUGIN="$root/fish/functions/sloctl_context.fish"
    fish -c '
        source "$FISH_PLUGIN"
        set -gx MOCK_CONTEXT first
        test (sloctl_context) = "N9:first"; or exit 1
        set -gx MOCK_CONTEXT second
        test (sloctl_context) = "N9:second"; or exit 1
        set -g SLOCTL_CONTEXT_PREFIX "["
        set -g SLOCTL_CONTEXT_SUFFIX "]"
        test (sloctl_context) = "[second]"; or exit 1
        set -gx MOCK_FAIL 1
        set -l empty_result (sloctl_context)
        test -z "$empty_result"; or exit 1
    '
    printf 'fish checks passed.\n'
else
    printf 'fish not installed; fish checks skipped.\n'
fi
