#!/bin/bash

# Script to scan Bitwarden entries and identify API keys
# This script will search for API keys in various fields (password, notes, custom fields)
# and help organize them systematically

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
    # Check for patterns like "sk-[...]", "pk-[...]", "Bearer [token]", etc.
    echo "$value" | grep -E "^[[:alnum:]_-]{20,}$|^[[:alnum:]_-]{30,}$|^(sk|pk|api|secret)[_-][[:alnum:]_-]{20,}$" >/dev/null
    return $?
}

# Function to extract domain from URL
extract_domain() {
    local url="$1"
    # Extract domain from URL
    echo "$url" | sed -E 's@https?://([^/]+).*@\1@' | sed -E 's@^www\.@@'
}

# Function to process a single Bitwarden item
process_item() {
    local item_id="$1"
    local item_json
    item_json=$(bw get item "$item_id" --session "$BW_SESSION")
    
    local name
    name=$(echo "$item_json" | jq -r '.name')
    echo "Processing: $name"
    
    # Check if this item looks like it contains API keys
    local has_api_key=false
    local api_key_field=""
    local api_key_value=""
    
    # Check the password field in login
    local password
    password=$(echo "$item_json" | jq -r '.login.password // empty')
    if [ -n "$password" ] && is_api_key_value "$password"; then
        has_api_key=true
        api_key_field="password"
        api_key_value="$password"
    fi
    
    # Check the notes field
    local notes
    notes=$(echo "$item_json" | jq -r '.notes // empty')
    if [ -z "$api_key_value" ] && [ -n "$notes" ] && is_api_key_value "$notes"; then
        has_api_key=true
        api_key_field="notes"
        api_key_value="$notes"
    fi
    
    # Check custom fields
    local fields
    fields=$(echo "$item_json" | jq -r '.fields[]? | @base64' 2>/dev/null) || true
    
    if [ -n "$fields" ]; then
        echo "$fields" | while read -r field; do
            if [ -n "$field" ]; then
                b64decode=$(echo "$field" | base64 -d)
                field_name=$(echo "$b64decode" | jq -r '.name')
                field_value=$(echo "$b64decode" | jq -r '.value')
                
                if [ -n "$field_value" ] && is_api_key_value "$field_value"; then
                    has_api_key=true
                    api_key_field="field: $field_name"
                    api_key_value="$field_value"
                    echo "  Found API key in custom field '$field_name'"
                fi
            fi
        done
    fi
    
    # Check URIs for domain extraction
    local uris
    uris=$(echo "$item_json" | jq -r '.login.uris[]?.uri // empty')
    
    if [ "$has_api_key" = true ]; then
        # Extract domain if URL is present
        local domain=""
        if [ -n "$uris" ]; then
            domain=$(extract_domain "$uris")
        fi
        
        # Output findings
        echo "  ✓ Found potential API key in $api_key_field"
        echo "  Name: $name"
        if [ -n "$domain" ]; then
            echo "  Domain: $domain"
        fi
        echo "  Value: ${api_key_value:0:20}..."  # Show first 20 chars only
        echo "---"
        return 0
    else
        # Check if item name suggests it might have API keys
        if is_api_key_item "$name"; then
            echo "  ? Item name suggests API key but no key pattern found"
            echo "  Name: $name"
            if [ -n "$uris" ]; then
                domain=$(extract_domain "$uris")
                echo "  Domain: $domain"
            fi
            echo "---"
        fi
        return 1
    fi
}

# Main function to scan all Bitwarden items
scan_bitwarden_items() {
    echo "Scanning Bitwarden items for API keys..."
    
    # Get all item IDs
    local item_ids
    item_ids=$(bw list items --session "$BW_SESSION" | jq -r '.[].id')
    
    if [ -z "$item_ids" ]; then
        echo "Error: Could not retrieve Bitwarden items. Make sure you are logged in and the session is valid."
        exit 1
    fi
    
    # Process each item
    echo "$item_ids" | while read -r item_id; do
        if [ -n "$item_id" ]; then
            process_item "$item_id"
        fi
    done
}

# Function to generate Chezmoi template for found API keys
generate_chezmoi_template() {
    echo "Generating Chezmoi template for API keys..."
    # This would be implemented to create template files based on findings
    echo "Template generation would happen here"
}

# Run main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_bw_auth
    scan_bitwarden_items
fi