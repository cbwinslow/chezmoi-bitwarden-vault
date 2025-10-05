#!/bin/bash

# Script to organize Bitwarden entries by standardizing API key field names and creating Chezmoi templates

set -e

# Function to check if we're logged in to Bitwarden
check_bw_auth() {
    if ! bw login --check >/dev/null 2>&1; then
        echo "Error: You are not logged in to Bitwarden. Please run 'bw login' first."
        exit 1
    fi
    
    # Unlock and set session if not already set
    if [ -z "$BW_SESSION" ]; then
        export BW_SESSION=$(bw unlock --raw --check)
        if [ -z "$BW_SESSION" ]; then
            echo "Error: Could not unlock Bitwarden vault. Please ensure you are properly logged in."
            exit 1
        fi
    fi
}

# Function to check if an item name contains API-related keywords
is_api_key_item() {
    local name="$1"
    echo "$name" | grep -iE "(api|token|key|secret|auth|credential)" >/dev/null
    return $?
}

# Function to check if a string matches common API key patterns
is_api_key_value() {
    local value="$1"
    # Common API key patterns (these are examples, can be extended)
    echo "$value" | grep -E "^[[:alnum:]_-]{20,}$|^[[:alnum:]_-]{30,}$|^(sk|pk|api|secret)[_-][[:alnum:]_-]{20,}$" >/dev/null
    return $?
}

# Function to extract domain from URL
extract_domain() {
    local url="$1"
    # Extract domain from URL
    echo "$url" | sed -E 's@https?://([^/]+).*@\1@' | sed -E 's@^www\.@@'
}

# Function to get the best API key value from an item
get_api_key_value() {
    local item_json="$1"
    
    # Check the password field
    local password=$(echo "$item_json" | jq -r '.login.password // empty')
    if [ -n "$password" ] && is_api_key_value "$password"; then
        echo "$password"
        return 0
    fi
    
    # Check the notes field
    local notes=$(echo "$item_json" | jq -r '.notes // empty')
    if [ -n "$notes" ] && is_api_key_value "$notes"; then
        echo "$notes"
        return 0
    fi
    
    # Check custom fields
    local fields=$(echo "$item_json" | jq -r '.fields[]? | @base64' 2>/dev/null) || return 1
    if [ -n "$fields" ]; then
        echo "$fields" | while read -r field; do
            if [ -n "$field" ]; then
                b64decode=$(echo "$field" | base64 -d)
                field_name=$(echo "$b64decode" | jq -r '.name')
                field_value=$(echo "$b64decode" | jq -r '.value')
                
                if [ -n "$field_value" ] && is_api_key_value "$field_value"; then
                    echo "$field_value"
                    return 0
                fi
            fi
        done
    fi
    
    return 1
}

# Function to get the field name that contains the API key
get_api_key_field_name() {
    local item_json="$1"
    
    # Check the password field
    local password=$(echo "$item_json" | jq -r '.login.password // empty')
    if [ -n "$password" ] && is_api_key_value "$password"; then
        echo "password"
        return 0
    fi
    
    # Check the notes field
    local notes=$(echo "$item_json" | jq -r '.notes // empty')
    if [ -n "$notes" ] && is_api_key_value "$notes"; then
        echo "notes"
        return 0
    fi
    
    # Check custom fields
    local fields=$(echo "$item_json" | jq -r '.fields[]? | @base64' 2>/dev/null) || return 1
    if [ -n "$fields" ]; then
        echo "$fields" | while read -r field; do
            if [ -n "$field" ]; then
                b64decode=$(echo "$field" | base64 -d)
                field_name=$(echo "$b64decode" | jq -r '.name')
                field_value=$(echo "$b64decode" | jq -r '.value')
                
                if [ -n "$field_value" ] && is_api_key_value "$field_value"; then
                    echo "$field_name"
                    return 0
                fi
            fi
        done
    fi
    
    return 1
}

# Function to generate a standardized name for the API key based on the original name and domain
generate_standard_name() {
    local original_name="$1"
    local domain="$2"
    
    # If we have a domain, use it to make the name more standardized
    if [ -n "$domain" ]; then
        # Convert to lowercase and use it in the name
        domain_lower=$(echo "$domain" | tr '[:upper:]' '[:lower:]')
        # Remove "www." prefix if present
        domain_clean=$(echo "$domain_lower" | sed 's/^www\.//')
        # Remove common suffixes
        domain_clean=$(echo "$domain_clean" | sed 's/\.com$//' | sed 's/\.org$//' | sed 's/\.net$//' | sed 's/\.io$//' | sed 's/\.ai$//' | sed 's/\.co$//')
        
        # If the original name contains "API", "Key", "Token", use that info
        if echo "$original_name" | grep -qi "api"; then
            echo "${domain_clean^}ApiKey"
        elif echo "$original_name" | grep -qi "token"; then
            echo "${domain_clean^}ApiToken"
        elif echo "$original_name" | grep -qi "key"; then
            echo "${domain_clean^}ApiKey"
        else
            echo "${domain_clean^}ApiKey"
        fi
    else
        # If no domain, use the original name with standardization
        echo "$original_name" | sed 's/ /_/g' | sed 's/[()]//g'
    fi
}

# Function to generate Chezmoi template for a found API key
generate_chezmoi_template_for_item() {
    local item_id="$1"
    local item_json="$2"
    local standard_name="$3"
    
    local name=$(echo "$item_json" | jq -r '.name')
    local api_key_value=$(get_api_key_value "$item_json")
    local api_key_field=$(get_api_key_field_name "$item_json")
    
    # Create the template content
    cat << TEMPLATE_EOF
# Template for $name
# This file can be used in your Chezmoi setup

{{/* Define API key for $name using Bitwarden */}}
{{- \$${standard_name,,} := (bitwarden "$name" "$api_key_field") -}}

# Example usage in a config file:
[$standard_name]
key = "{{ \$${standard_name,,} }}"
TEMPLATE_EOF
}

# Main function to process and organize Bitwarden items
organize_bitwarden_items() {
    echo "Organizing Bitwarden items and creating Chezmoi templates..."
    
    # Get all item IDs
    local item_ids
    item_ids=$(bw list items --session "$BW_SESSION" | jq -r '.[].id')
    
    if [ -z "$item_ids" ]; then
        echo "Error: Could not retrieve Bitwarden items. Make sure you are logged in and the session is valid."
        exit 1
    fi
    
    # Create directory for templates
    mkdir -p chezmoi-templates-generated
    
    # Process each item
    echo "$item_ids" | while read -r item_id; do
        if [ -n "$item_id" ]; then
            local item_json
            item_json=$(bw get item "$item_id" --session "$BW_SESSION")
            
            local name
            name=$(echo "$item_json" | jq -r '.name')
            
            # Check if this item contains an API key
            if api_key_value=$(get_api_key_value "$item_json"); then
                if [ $? -eq 0 ]; then
                    # Extract domain from URL if available
                    local uri
                    uri=$(echo "$item_json" | jq -r '.login.uris[0].uri // empty')
                    local domain=""
                    if [ -n "$uri" ]; then
                        domain=$(extract_domain "$uri")
                    fi
                    
                    # Generate a standardized name
                    local standard_name
                    standard_name=$(generate_standard_name "$name" "$domain")
                    
                    echo "Found API key in: $name -> Standardized as: $standard_name"
                    
                    # Generate Chezmoi template for this item
                    generate_chezmoi_template_for_item "$item_id" "$item_json" "$standard_name" > "chezmoi-templates-generated/${standard_name,,}.tmpl"
                    
                    echo "  Created template: chezmoi-templates-generated/${standard_name,,}.tmpl"
                fi
            fi
        fi
    done
    
    echo "Generated templates saved to chezmoi-templates-generated/ directory"
}

# Function to generate a master config template that includes all API keys
generate_master_config() {
    echo "Generating master configuration template..."
    
    cat > "chezmoi-templates-generated/master-config.tmpl" << 'MASTER_EOF'
# Master configuration template with all API keys

{{/* Include all individual API keys */}}

# Generated section - API Keys
{{- range $path, $bytes := (includeFiles "chezmoi-templates-generated/*.tmpl") }}
{{ $path }}:
{{ $bytes }}
{{- end }}

# Individual API keys can be used in specific contexts
# Example: 
# [services]
# openai_api_key = "{{ .OpenaiApiKey }}"
# anthropic_api_key = "{{ .AnthropicApiKey }}"
MASTER_EOF
    
    echo "Created master configuration template: chezmoi-templates-generated/master-config.tmpl"
}

# Run main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_bw_auth
    organize_bitwarden_items
    generate_master_config
    echo
    echo "Setup complete! You now have:"
    echo "1. Individual templates for each API key in chezmoi-templates-generated/"
    echo "2. A master template that can include all API keys"
    echo "3. Standardized naming for your API keys"
    echo
    echo "To use these with Chezmoi:"
    echo "1. Move the templates to your chezmoi directory (e.g., ~/.local/share/chezmoi/)"
    echo "2. Create or modify your chezmoi configuration to use these templates"
    echo "3. Run 'chezmoi apply' to generate your configuration files"
fi