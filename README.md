# sloctl context prompt

Show the current [sloctl](https://github.com/nobl9/sloctl) default context in your shell prompt:

```text
N⁹:production
```

The context is refreshed when the prompt is rendered, so it follows `sloctl config use-context` and changes made in another terminal. The plugin does not modify your shell configuration or prompt automatically, except that the optional Powerlevel10k integration adds one segment to its in-memory list.

## Requirements

- `sloctl` on your `PATH`, with the `config current-context` command.
- A clone or downloaded copy of this project in a stable location. In the examples below, replace `/path/to/sloctl-context` with its actual path.
- A UTF-8 terminal and a font with `⁹` for the default prefix. See [Customization](#customization) for an ASCII alternative.

Clone the repository if you have not already:

```sh
git clone https://github.com/greg-agacinski/sloctl-context.git
```

Choose **one** prompt integration below. Plugin managers load functions; prompt themes decide what is displayed. Loading a plugin alone does not add it to a theme's prompt.

## Powerlevel10k

Add to the **end** of `~/.zshrc`, after Powerlevel10k, `~/.p10k.zsh`, and other prompt scripts:

```zsh
source /path/to/sloctl-context/sloctl-context-powerlevel10k.zsh
```

Restart zsh. The integration adds `sloctl_context` to the right prompt unless it already appears in either prompt array. To choose its position, add `sloctl_context` to `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS` or `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` in `~/.p10k.zsh` before the integration is sourced. Do not put it in both arrays unless you want it twice.

If you reload `~/.p10k.zsh` on its own, source the integration again afterward because the configuration resets the segment lists. Powerlevel10k can hide the right prompt when there is not enough space. If the segment is missing, check that the integration is sourced and run `sloctl_context` to inspect its output.

## Oh My Zsh and other zsh plugin managers

For [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Customization), link this directory into the custom plugin directory:

```zsh
mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
ln -s /path/to/sloctl-context "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/sloctl-context"
```

Add `sloctl-context` to the existing `plugins=(...)` array in `~/.zshrc`, **before** `source $ZSH/oh-my-zsh.sh`:

```zsh
plugins=(git sloctl-context)  # keep your other plugins too
```

Restart zsh. For a plain zsh prompt, also follow the next section, omitting its `source` line. If you use Powerlevel10k, follow its section instead: the plugin-manager entry point loads the function, while the Powerlevel10k file registers the segment.

Other zsh plugin managers can load `sloctl-context.plugin.zsh` as their entry point. Configure your manager to load this local directory using that manager's instructions; then add the function to your theme as appropriate.

## Plain zsh

Add to `~/.zshrc`, after any code that sets `PROMPT`:

```zsh
source /path/to/sloctl-context/sloctl-context.plugin.sh
setopt prompt_subst
PROMPT='$(sloctl_context) '"$PROMPT"
```

Alternatively insert `$(sloctl_context)` into an existing prompt or use `RPROMPT`. Keep the command substitution in single quotes when assigning the prompt so it executes at each prompt. Sourcing the configuration repeatedly may prepend the segment multiple times; start a fresh shell when testing setup. A theme may replace `PROMPT` later: use the theme's custom-segment mechanism instead.

## Bash

Add to `~/.bashrc`, after any code that sets `PS1`:

```bash
source /path/to/sloctl-context/sloctl-context.plugin.sh
PS1='$(sloctl_context) '"$PS1"
```

Start a new shell or source `~/.bashrc` once. On macOS, login shells may use `~/.bash_profile`; ensure it loads your `.bashrc` if applicable. Prompt frameworks may overwrite `PS1` and require their own custom-segment mechanism.

## fish

Add this line to `~/.config/fish/config.fish`:

```fish
source /path/to/sloctl-context/fish/functions/sloctl_context.fish
```

Add the following inside your existing `fish_prompt` or `fish_right_prompt` function where you want the segment:

```fish
set -l sloctl_segment (sloctl_context)
if test -n "$sloctl_segment"
    printf '%s ' "$sloctl_segment"
end
```

Do not replace an existing prompt function without preserving its contents. If a prompt theme owns the function, follow that theme's custom-segment instructions. See the [fish prompt documentation](https://fishshell.com/docs/current/cmds/fish_prompt.html).

## Starship

Starship owns prompt rendering, so configure its [custom command module](https://starship.rs/config/#custom-commands) in `~/.config/starship.toml`. This Unix example calls `sloctl` directly and does not need the shell plugin files:

```toml
[custom.sloctl_context]
command = 'sloctl config current-context 2>/dev/null'
when = true
shell = ['sh']
format = '(N[⁹:$output]($style) )'
style = 'bold #1eb8d1'
```

The parentheses make the whole segment conditional on nonempty command output. If you have an explicit top-level `format` or `right_format`, include `${custom.sloctl_context}` at the desired location; remove `$custom` if it would otherwise render the same module twice. Starship's `command_timeout` also applies. This example requires `sh`; on Windows use a shell appropriate to your Starship configuration. Keep Starship's output escaping enabled and use Starship 1.20 or newer; earlier versions did not escape custom command output by default.

## Customization

The Powerlevel10k segment uses your terminal’s default foreground for `N` and turquoise (`#1eb8d1`), matching the Nobl9 logo, for the rest. The default foreground normally follows your terminal’s light or dark color scheme. To use a different color, set this in `~/.p10k.zsh`:

```zsh
typeset -g POWERLEVEL9K_SLOCTL_CONTEXT_FOREGROUND=cyan
```

Powerlevel10k handles color rendering and honors terminal capabilities. The plain bash, zsh, and fish functions print uncolored text so that your prompt or theme can style it. The Starship example sets its own turquoise style.

For bash, zsh, Powerlevel10k, and fish, set `SLOCTL_CONTEXT_PREFIX` and/or `SLOCTL_CONTEXT_SUFFIX` before the prompt is drawn. Empty strings are allowed. The defaults are `N⁹:` and an empty suffix.

```sh
# bash or zsh: ASCII example
SLOCTL_CONTEXT_PREFIX='n9:'
SLOCTL_CONTEXT_SUFFIX=''
```

In fish, use `set -g SLOCTL_CONTEXT_PREFIX 'n9:'`. For Starship, change the module's `format` and `style` instead. zsh interprets `%` sequences in prompts; the function escapes `%` in context names, while prefix and suffix can contain intentional zsh prompt formatting.

## Behavior and troubleshooting

- The segment is empty when `sloctl` is missing, fails, or returns an empty name. Run `sloctl config current-context` directly to see errors.
- The command uses the CLI's normal configuration selection, including `SLOCTL_CONFIG_FILE_PATH` where supported. Depending on the installed `sloctl` version, it can create a default configuration file if none exists.
- It displays the configured default context, not a one-command `--context` override or environment-only authentication.
- Each prompt starts `sloctl`; this incurs its startup and local configuration loading time. No cache is used, so changes in other terminals are reflected on the next prompt.
- Avoid sourcing the plain zsh or bash prompt setup more than once in a session, as doing so can duplicate its prompt text.

## Tests

Run `bash tests/test.sh`. It uses a mock `sloctl` and checks bash and zsh. Powerlevel10k and fish checks run when those programs are available; `P10K_THEME` can point to a Powerlevel10k theme file. The tests do not access your sloctl configuration. Run `python3 tests/interactive.py` to test interactive bash, zsh, Oh My Zsh and Powerlevel10k prompts in a temporary home directory when available. Run `bash tests/docker-test.sh` to test bash, zsh, fish and Starship in a disposable Alpine container. The first run downloads the image and packages; Docker is required. Oh My Zsh and Powerlevel10k are tested by the interactive script when installed on the host.

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for development and test instructions.

## License

[GNU General Public License v3.0](LICENSE).
