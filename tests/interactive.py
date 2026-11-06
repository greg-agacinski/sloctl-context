#!/usr/bin/env python3
"""Exercise real interactive prompts with isolated HOME and a mock sloctl."""
import os
import pathlib
import select
import shutil
import subprocess
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
OMZ = pathlib.Path.home() / '.oh-my-zsh'
P10K = OMZ / 'custom/themes/powerlevel10k/powerlevel10k.zsh-theme'


def wait_for(fd, expected, timeout=15):
    data = b''
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        ready, _, _ = select.select([fd], [], [], min(0.2, end-time.monotonic()))
        if ready:
            try:
                data += os.read(fd, 65536)
            except OSError:
                break
            if expected.encode() in data:
                return
    raise AssertionError(f'missing {expected!r} in terminal output {data[-2000:]!r}')


def run_prompt(name, executable, arguments, config, env, context_file):
    home = pathlib.Path(env['HOME'])
    if name == 'bash':
        rcfile = home / 'bashrc'
        rcfile.write_text(config)
        arguments = ['--noprofile', '--rcfile', str(rcfile), '-i']
    else:
        (home / '.zshrc').write_text(config)
    context_file.write_text('first')
    import pty
    master, slave = pty.openpty()
    proc = subprocess.Popen([executable, *arguments], stdin=slave, stdout=slave,
                            stderr=slave, env=env, start_new_session=True, close_fds=True)
    os.close(slave)
    try:
        wait_for(master, 'N⁹:first')
        context_file.write_text('second')
        os.write(master, b'\n')
        wait_for(master, 'N⁹:second')
        context_file.write_text('name%F{red}')
        os.write(master, b'\n')
        wait_for(master, 'N⁹:name%F{red}')
        print(f'{name}: interactive prompt, refresh and literal percent passed')
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        os.close(master)


def main():
    with tempfile.TemporaryDirectory(prefix='sloctl-prompt-test-') as temp:
        base = pathlib.Path(temp)
        home = base / 'home'
        home.mkdir()
        bindir = base / 'bin'
        bindir.mkdir()
        context_file = base / 'context'
        mock = bindir / 'sloctl'
        mock.write_text('#!/bin/sh\n[ "$*" = "config current-context" ] || exit 1\ncat "$MOCK_CONTEXT_FILE"\n')
        mock.chmod(0o755)
        env = os.environ.copy()
        env.update(HOME=str(home), ZDOTDIR=str(home), MOCK_CONTEXT_FILE=str(context_file),
                   TERM='xterm-256color', PATH=str(bindir) + os.pathsep + os.environ['PATH'])
        env.pop('SLOCTL_CONTEXT_PREFIX', None)
        env.pop('SLOCTL_CONTEXT_SUFFIX', None)
        bash = shutil.which('bash')
        zsh = shutil.which('zsh')
        run_prompt('bash', bash, [],
                   f"source '{ROOT}/sloctl-context.plugin.sh'\nPS1='$(sloctl_context) > '\n", env, context_file)
        run_prompt('zsh', zsh, ['-d', '-i'],
                   f"source '{ROOT}/sloctl-context.plugin.sh'\nsetopt prompt_subst\nPROMPT='$(sloctl_context) > '\n", env, context_file)
        if (OMZ / 'oh-my-zsh.sh').exists():
            custom = home / 'custom'
            (custom / 'plugins').mkdir(parents=True, exist_ok=True)
            (custom / 'plugins/sloctl-context').symlink_to(ROOT)
            common = (f"export ZSH='{OMZ}'\nexport ZSH_CUSTOM='{custom}'\n"
                      "zstyle ':omz:update' mode disabled\nplugins=(sloctl-context)\n")
            run_prompt('oh-my-zsh', zsh, ['-d', '-i'], common +
                       "ZSH_THEME=''\nsource $ZSH/oh-my-zsh.sh\nsetopt prompt_subst\n"
                       "PROMPT='$(sloctl_context) > '\n", env, context_file)
            if P10K.exists():
                (custom / 'themes').mkdir(exist_ok=True)
                (custom / 'themes/powerlevel10k').symlink_to(P10K.parent)
                run_prompt('powerlevel10k', zsh, ['-d', '-i'], common +
                           "ZSH_THEME=powerlevel10k/powerlevel10k\n"
                           "POWERLEVEL9K_DISABLE_GITSTATUS=true\nPOWERLEVEL9K_INSTANT_PROMPT=off\n"
                           "source $ZSH/oh-my-zsh.sh\n"
                           "POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir prompt_char)\n"
                           "POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()\n" +
                           f"source '{ROOT}/sloctl-context-powerlevel10k.zsh'\n", env, context_file)
        if not shutil.which('fish'):
            print('fish: skipped (not installed)')
        if not shutil.which('starship'):
            print('starship: skipped (not installed)')

if __name__ == '__main__':
    main()
