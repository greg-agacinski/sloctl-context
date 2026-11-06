#!/usr/bin/env python3
"""Check the README's Starship module against a mock sloctl."""
import os
import pathlib
import re
import subprocess
import tempfile
import tomllib

ROOT = pathlib.Path(__file__).resolve().parent.parent
readme = (ROOT / 'README.md').read_text()
match = re.search(r'```toml\n(\[custom\.sloctl_context\].*?)\n```', readme, re.S)
if not match:
    raise SystemExit('Starship configuration missing from README')
config = match.group(1)
tomllib.loads(config)

with tempfile.TemporaryDirectory(prefix='sloctl-starship-test-') as temp:
    base = pathlib.Path(temp)
    mock = base / 'sloctl'
    mock.write_text('#!/bin/sh\n[ "$*" = "config current-context" ] || exit 2\n'
                    '[ "${MOCK_FAIL-}" != 1 ] || exit 1\nprintf "%s\\n" "${MOCK_CONTEXT-}"\n')
    mock.chmod(0o755)
    config_path = base / 'starship.toml'
    config_path.write_text(config + '\n')
    env = dict(os.environ, HOME=str(base), STARSHIP_CONFIG=str(config_path),
               PATH=str(base) + os.pathsep + os.environ['PATH'], NO_COLOR='1', TERM='dumb')

    def render(context, fail='0'):
        output = subprocess.run(['starship', 'module', 'custom.sloctl_context'],
                                env=dict(env, MOCK_CONTEXT=context, MOCK_FAIL=fail),
                                text=True, capture_output=True, check=True).stdout
        return re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', output)

    for name in ('first', 'second'):
        result = render(name)
        assert f'N⁹:{name}' in result, repr(result)
    assert 'N⁹:' not in render(''), 'empty context must be hidden'
    assert 'N⁹:' not in render('first', fail='1'), 'failed command must be hidden'
print('Starship: module renders, refreshes and hides on failure')
