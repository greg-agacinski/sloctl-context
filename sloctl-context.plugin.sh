# Source this file from bash or zsh, then add sloctl_context to your prompt.
# The command is intentionally run at prompt time so changes are reflected.
sloctl_context() {
    command -v sloctl >/dev/null 2>&1 || return 0
    local context
    context=$(command sloctl config current-context 2>/dev/null) || return 0
    [ -n "$context" ] || return 0

    # zsh interprets percent sequences in the result of prompt substitution.
    if [ -n "${ZSH_VERSION-}" ]; then
        context=${context//\%/%%}
    fi
    printf '%s%s%s' "${SLOCTL_CONTEXT_PREFIX-N⁹:}" "$context" "${SLOCTL_CONTEXT_SUFFIX-}"
}
