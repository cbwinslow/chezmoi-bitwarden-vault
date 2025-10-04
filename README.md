# Chezmoi Bitwarden Vault

A comprehensive secret management system that integrates Chezmoi, Bitwarden, and Vault for secure configuration management.

## Overview

This project provides a secure system for managing secrets in your dotfiles and configurations. It combines:

- **Chezmoi**: For managing dotfiles across multiple machines
- **Bitwarden**: For storing and retrieving sensitive data like API keys
- **Vault**: For additional secret storage capabilities
- **Custom scripts**: For seamless integration between tools

## Features

- Secure retrieval of secrets from Bitwarden
- Template-based configuration generation
- Session-based authentication with Bitwarden
- Helper scripts for common operations
- Integration with existing Chezmoi workflows

## Prerequisites

- Bitwarden CLI (`bw`)
- Chezmoi
- Vault (optional)
- Git

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/chezmoi-bitwarden-vault.git
   ```

2. Make the helper scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

3. Add the scripts directory to your PATH or copy scripts to `~/.local/bin/`

## Usage

### 1. Basic Setup

Run the setup script to configure your system:
```bash
./scripts/setup_bitwarden_chezmoi.sh
```

### 2. Authentication

Authenticate with Bitwarden:
```bash
bw login
export BW_SESSION=$(bw unlock --raw)
```

### 3. Using in Chezmoi Templates

Create templates that retrieve secrets from Bitwarden:
```bash
{{- $key := (bitwarden "OpenAI API Key") -}}
api_key = "{{ $key }}"
```

### 4. Helper Scripts

The project includes several helper scripts:

- `bw-helper`: Wrapper for Bitwarden commands with session management
- `bw-template`: Template function for getting specific fields from Bitwarden items
- `setup_bitwarden_chezmoi.sh`: Setup script for initial configuration

## Configuration

The system uses the following configuration:

- `~/.config/chezmoi/chezmoi.toml`: Chezmoi configuration with Bitwarden integration
- Session tokens stored securely in `~/.bw_session_token` (not in this repository)

## Security

- Session tokens are not stored in plain text in Git
- Helper scripts manage session tokens securely
- Templates separate secrets from configuration files
- Proper file permissions are enforced

## Example Template

Create a template file `example-config.tmpl` in your chezmoi directory:

```toml
# Example configuration with Bitwarden secrets
[api_keys]
# openai = "{{ .Bitwarden "OpenAI API Key" "password" }}"
# anthropic = "{{ .Bitwarden "Anthropic API Key" "password" }}"

# Using the template function:
{{- $openai_key := (bitwarden "OpenAI API Key") -}}
openai_key = "{{ $openai_key }}"

{{- $anthropic_key := (bitwarden "Anthropic API Key") -}}
anthropic_key = "{{ $anthropic_key }}"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Commit and push
5. Open a pull request

## License

MIT License - see the LICENSE file for details.

## Troubleshooting

If you encounter issues:

1. Verify Bitwarden CLI is installed and accessible
2. Check that you're logged in to Bitwarden
3. Ensure the BW_SESSION environment variable is set
4. Verify file permissions on helper scripts
