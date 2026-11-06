# sloctl context prompt

Show the default [sloctl](https://github.com/nobl9/sloctl) context in a bash or zsh prompt. The display refreshes each time the prompt is drawn, including after `sloctl config use-context`.

## Setup

Clone or download this directory, then add the appropriate lines to your shell configuration. Replace the path with the location of `sloctl-context.plugin.sh`.

### Powerlevel10k (zsh)

Add this line at the **end** of `~/.zshrc`, after loading Powerlevel10k, `~/.p10k.zsh`, and any other prompt scripts:

```zsh
source /path/to/sloctl-context-powerlevel10k.zsh
```

This adds a custom segment to the right-hand Powerlevel10k prompt without replacing your existing segments. Keep `sloctl-context.plugin.sh` in the same directory as the Powerlevel10k file. If you reload `~/.p10k.zsh` separately, source the Powerlevel10k integration again afterward, since the configuration resets the segment list. The Powerlevel10k prompt may hide right-hand segments when the command line is too long.

### zsh without Powerlevel10k

Add to `~/.zshrc`:

```zsh
source /path/to/sloctl-context.plugin.sh
setopt prompt_subst
PROMPT='$(sloctl_context) '"$PROMPT"
```

You can use `RPROMPT` instead of `PROMPT` if you prefer the right-hand side. If you use a prompt theme, follow its instructions for adding a custom prompt segment; themes can overwrite `PROMPT` or `RPROMPT`.

### bash

Add to `~/.bashrc` (or the startup file used by your shell):

```bash
source /path/to/sloctl-context.plugin.sh
PS1='$(sloctl_context) '"$PS1"
```

Restart your shell or source your shell configuration. For example, a context named `production` appears as `(slo:production)`.

## Customize

Set either variable before the prompt is displayed; empty strings are allowed:

```sh
SLOCTL_CONTEXT_PREFIX='[nobl9:'
SLOCTL_CONTEXT_SUFFIX=']'
```

To use the function in an existing prompt, insert `$(sloctl_context)` where you want the segment. Keep it in single quotes when assigning the prompt so it runs for each prompt, rather than only during setup. The function prints nothing if `sloctl` is unavailable, the command fails, or it returns an empty name.

The plugin runs `sloctl config current-context` at every prompt. This adds the CLI's startup time to prompt rendering. The command uses the CLI's normal configuration selection, including `SLOCTL_CONFIG_FILE_PATH`; depending on the installed version, it can create a default configuration file if one does not exist. It displays the configured default context, not a one-command `--context` override or environment-only authentication.

## Check

Run `bash tests/test.sh` to exercise the plugin with a mock CLI in both bash and zsh. If Powerlevel10k is installed at its usual Oh My Zsh path, the tests also check that its prompt updates after context changes. Set `P10K_THEME` to its theme file to test another installation. The tests do not access your sloctl configuration.
