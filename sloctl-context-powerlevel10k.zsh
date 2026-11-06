# Source after Powerlevel10k and its configuration have loaded.
source "${${(%):-%x}:A:h}/sloctl-context.plugin.sh"

function prompt_sloctl_context() {
    local text
    # Use the terminal's default foreground for N, then restore the segment color.
    if (( ! ${+SLOCTL_CONTEXT_PREFIX} )); then
        local SLOCTL_CONTEXT_PREFIX="%fN%F{${POWERLEVEL9K_SLOCTL_CONTEXT_FOREGROUND:-#1eb8d1}}9:"
    fi
    text=$(sloctl_context)
    [[ -n $text ]] || return 0
    p10k segment -f "#1eb8d1" -t "$text"
}

# Avoid adding the segment twice when this file is sourced again.
if (( ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[(Ie)sloctl_context]} == 0 &&
      ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(Ie)sloctl_context]} == 0 )); then
    POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=(sloctl_context)
fi
