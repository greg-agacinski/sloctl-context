function sloctl_context --description 'Print the current sloctl context for a prompt'
    type -q sloctl; or return 0
    set -l context (command sloctl config current-context 2>/dev/null); or return 0
    test -n "$context"; or return 0

    set -l prefix 'N⁹:'
    set -l suffix ''
    set -q SLOCTL_CONTEXT_PREFIX; and set prefix "$SLOCTL_CONTEXT_PREFIX"
    set -q SLOCTL_CONTEXT_SUFFIX; and set suffix "$SLOCTL_CONTEXT_SUFFIX"
    printf '%s%s%s' "$prefix" "$context" "$suffix"
end
