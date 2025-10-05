#!/bin/bash

# Demo script to set up and demonstrate the Chezmoi Bitwarden integration
# This script will help you set up your Chezmoi with templates for API keys

set -e

echo "Setting up Chezmoi with Bitwarden API key templates..."
echo

# Check if chezmoi is installed
if ! command -v chezmoi >/dev/null 2>&1; then
    echo "Error: chezmoi is not installed. Please install it first."
    exit 1
fi

# Check if bw (Bitwarden CLI) is installed
if ! command -v bw >/dev/null 2>&1; then
    echo "Error: Bitwarden CLI (bw) is not installed. Please install it first."
    exit 1
fi

# Check Bitwarden authentication
if ! bw login --check >/dev/null 2>&1; then
    echo "Error: You are not logged in to Bitwarden. Please run 'bw login' first."
    exit 1
fi

echo "✓ All required tools are installed"
echo

# Create demo configuration
echo "Creating a demo configuration..."

# Create demo directory structure
mkdir -p demo-dotfiles/.chezmoi

# Create a demo config template that uses Bitwarden for API keys
cat > demo-dotfiles/.chezmoi/config.tmpl << 'CONFIG_EOF'
# Example configuration template using Bitwarden API keys

{{- $openai_api_key := (bitwarden "OpenAI API Key" "password") -}}
{{- $anthropic_api_key := (bitwarden "Anthropic API Key" "password") -}}

# API Configuration
[api]
openai_key = "{{ $openai_api_key }}"
anthropic_key = "{{ $anthropic_api_key }}"

# Other configurations could use other Bitwarden entries
# For example, database credentials, SSH keys, etc.
CONFIG_EOF

echo "✓ Created demo configuration template"

# Create a sample application configuration
cat > demo-dotfiles/.chezmoi/private_dot_aider.conf.yml.tmpl << 'AIDER_EOF'
# Aider configuration using Bitwarden API keys
{{- $openai_api_key := (bitwarden "OpenAI API Key" "password") -}}
{{- $anthropic_api_key := (bitwarden "Anthropic API Key" "password") -}}

# Model providers
model: gpt-4o
openai-api-key: "{{ $openai_api_key }}"
anthropic-api-key: "{{ $anthropic_api_key }}"
# You can add other configuration options here
AIDER_EOF

echo "✓ Created demo Aider configuration template"

# Create a sample shell environment file
cat > demo-dotfiles/.chezmoi/private_dot_env.tmpl << 'ENV_EOF'
# Environment variables using Bitwarden API keys
{{- $openai_api_key := (bitwarden "OpenAI API Key" "password") -}}
{{- $anthropic_api_key := (bitwarden "Anthropic API Key" "password") -}}

export OPENAI_API_KEY="{{ $openai_api_key }}"
export ANTHROPIC_API_KEY="{{ $anthropic_api_key }}"
# Add other environment variables as needed
ENV_EOF

echo "✓ Created demo environment variables template"

# Create README for the demo
cat > demo-dotfiles/.chezmoi/README.md << 'README_EOF'
# Demo Configuration for Chezmoi + Bitwarden

This demo shows how to use Bitwarden to store API keys and other secrets, 
which are then retrieved by Chezmoi when generating your configurations.

## How it works:

1. API keys are stored in Bitwarden with appropriate names
2. Chezmoi templates use the `bitwarden` function to retrieve the values
3. When you run `chezmoi apply`, your configuration files are generated
   with the actual API keys inserted

## Prerequisites:

- Bitwarden CLI installed (`bw`)
- You must be logged into Bitwarden
- Chezmoi configured to work with Bitwarden

## Example Usage:

```bash
# Set your Bitwarden session (if not already set)
export BW_SESSION=$(bw unlock --raw)

# Apply the templates to generate your configuration
chezmoi apply
```

Note: The templates use the bitwarden template function that we configured earlier.
This function looks for Bitwarden items by name and can retrieve specific fields.

For a complete setup:
1. Run the organize-bw-items.sh script to scan your Bitwarden vault
2. It will create standardized templates for all your API keys
3. Use those templates in your main Chezmoi setup
README_EOF

echo "✓ Created demo README"

# Show instructions
echo
echo "Demo setup complete! Here's how to use it:"
echo
echo "1. Make sure you have API keys stored in Bitwarden with these names:"
echo "   - 'OpenAI API Key' (with the key in the password field)"
echo "   - 'Anthropic API Key' (with the key in the password field)"
echo
echo "2. Authenticate with Bitwarden:"
echo "   export BW_SESSION=$(bw unlock --raw)"
echo
echo "3. Initialize Chezmoi with this demo directory:"
echo "   chezmoi init ~/Projects/chezmoi-bitwarden-vault/demo-dotfiles"
echo
echo "4. Apply the templates to generate your configurations:"
echo "   chezmoi apply"
echo
echo "Note: The templates use the bitwarden template function that we configured earlier."
echo "This function looks for Bitwarden items by name and can retrieve specific fields."
echo
echo "For a complete setup:"
echo "1. Run the organize-bw-items.sh script to scan your Bitwarden vault"
echo "2. It will create standardized templates for all your API keys"
echo "3. Use those templates in your main Chezmoi setup"