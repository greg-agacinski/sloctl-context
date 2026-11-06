# Contributing

Issues and pull requests are welcome. For a bug report, include the shell and version, prompt framework, `sloctl` version, expected behavior, and steps to reproduce. Remove credentials, tokens, and sensitive context names from examples and logs.

For a change:

1. Fork the repository and create a branch.
2. Make the change and update the README if setup or behavior changes.
3. Run `bash tests/docker-test.sh` with Docker available. See the README for other test options.
4. Open a pull request describing the change and how you tested it.

The Docker tests cover bash, zsh, fish, and Starship. The interactive tests also exercise Oh My Zsh and Powerlevel10k when those are installed on the host. Please mention any integrations you could not test.
