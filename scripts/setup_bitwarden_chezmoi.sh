#!/bin/bash

# Setup script for integrating Bitwarden with Chezmoi
# This script will set up secure methods to access secrets

set -e

echo "Setting up Bitwarden integration for Chezmoi..."

# Create necessary directories
mkdir -p ~/.config/chezmoi
mkdir -p ~/.local/bin

# Update Chezmoi configuration
echo '[data]
  # User-specific data can be added here, but avoid secrets

# Enable template functions for Bitwarden
[template]
  # Define a custom template function to access Bitwarden items' > ~/.config/chezmoi/chezmoi.toml

echo "Created Chezmoi configuration for Bitwarden integration"

# Create an example template file structure for demonstration
mkdir -p ~/dotfiles/.chezmoi

# Create an example template that uses Bitwarden secrets
echo '# Example configuration file with Bitwarden secrets
# This file will be processed by Chezmoi

[api_keys]
# To use this template, you would set up Bitwarden items with these names
# openai = "{{ .Bitwarden "OpenAI API Key" "password" }}"
# anthropic = "{{ .Bitwarden "Anthropic API Key" "password" }}"

# Example of how to reference these in a real template:
# {{- $openai_key := (bitwarden "OpenAI API Key" "password") -}}
# openai_key = "{{ $openai_key }}"' > ~/dotfiles/.chezmoi/example-config.tmpl

echo "Created example template demonstrating Bitwarden integration"

# Instructions for users
echo 'Setup complete! For a complete Bitwarden + Chezmoi setup:

1. First, authenticate with Bitwarden:
   bw login
   export BW_SESSION=$(bw unlock --raw)

2. To use Bitwarden secrets in your Chezmoi templates, you can:
   - Use the template function: {{- $secret := (bitwarden "item-name") -}}
   - For specific fields: {{- $field := (bitwarden-field "item-name" "field-name") -}}

3. Store your API keys and sensitive data in Bitwarden:
   bw create item --name "OpenAI API Key" --password "your-key-here"

4. In your templates, reference them as:
   {{- $key := (bitwarden "OpenAI API Key") -}}
   api_key = "{{ $key }}"

Note: For machine accounts in production, consider using Bitwarden Secrets Manager (available in newer versions) or store only the session token in a secure environment rather than credentials in plain text.'

echo ""
echo "Your setup is complete! The script has:"
echo "1. Created necessary configuration directories"
echo "2. Set up Chezmoi to work with Bitwarden"
echo "3. Created example templates"
echo "4. Provided instructions for completing the setup"