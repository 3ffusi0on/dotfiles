#!/bin/bash

# Auto Branch Creator with AI - Uses GitHub Copilot CLI or Gemini CLI

# Configuration - Choose your AI CLI
AI_CLI="copilot"  # Options: "copilot" or "gemini"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Check for changes
changes=$(git diff --cached --name-only && git diff --name-only)
if [ -z "$changes" ]; then
    echo "No changes detected. Nothing to create a branch for."
    exit 1
fi

echo "=== AI Auto Branch Creator ==="
echo "Using AI CLI: $AI_CLI"
echo "Analyzing changes..."
echo ""

# Get git diff summary (limit size for API)
diff_summary=$(git diff --cached --stat && git diff --stat)
file_list=$(echo "$changes" | tr '\n' ', ' | sed 's/,$//')

# Generate branch name using selected AI CLI
if [ "$AI_CLI" = "copilot" ]; then
    # GitHub Copilot CLI - using explain command which is non-interactive
    if ! command -v gh &> /dev/null || ! gh copilot --version &> /dev/null 2>&1; then
        echo "Error: GitHub Copilot CLI not found."
        echo "Install with: gh extension install github/gh-copilot"
        exit 1
    fi

    # Create a temporary file with the prompt
    temp_file=$(mktemp)
    echo "Suggest a git branch name (format: type/short-description like feature/add-login or fix/auth-bug) for these changes. Output ONLY the branch name." > "$temp_file"
    echo "" >> "$temp_file"
    echo "Files: $file_list" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "$diff_summary" >> "$temp_file"

    # Use gh copilot explain and parse output
    branch_name=$(gh copilot explain "$(cat $temp_file)" 2>/dev/null | grep -oE '(feature|fix|bugfix|hotfix|refactor|docs|style|test|chore)/[a-z0-9-]+' | head -1)

    rm "$temp_file"

    # If that didn't work, try a simpler approach
    if [ -z "$branch_name" ]; then
        # Fallback: use first changed file to generate branch name
        first_file=$(echo "$changes" | head -1 | sed 's/\.[^.]*$//' | tr '/' '-' | tr '[:upper:]' '[:lower:]')
        branch_name="feature/${first_file}"
    fi

elif [ "$AI_CLI" = "gemini" ]; then
    # Gemini CLI
    if ! command -v gemini &> /dev/null; then
        echo "Error: Gemini CLI not found."
        echo "Install with: npm install -g gemini-cli"
        echo "Then configure with: gemini config set apiKey YOUR_API_KEY"
        exit 1
    fi

    prompt="Suggest a git branch name (format: type/short-description like feature/add-login or fix/auth-bug) for these changes. Output ONLY the branch name, nothing else.

Files: $file_list

$diff_summary"

    branch_name=$(printf "%s" "$prompt" | gemini --no-stream 2>/dev/null | grep -oE '(feature|fix|bugfix|hotfix|refactor|docs|style|test|chore)/[a-z0-9-]+' | head -1)

    # Fallback if AI doesn't return expected format
    if [ -z "$branch_name" ]; then
        ai_response=$(printf "%s" "$prompt" | gemini --no-stream 2>/dev/null | tail -1 | tr -d '"' | xargs)
        branch_name=$(echo "$ai_response" | sed 's/[^a-zA-Z0-9/_-]//g')
    fi

else
    echo "Error: Invalid AI_CLI configuration. Use 'copilot' or 'gemini'"
    exit 1
fi

# Validate and clean branch name
if [ -z "$branch_name" ]; then
    echo "Error: Failed to generate branch name"
    exit 1
fi

# Clean branch name (remove any extra formatting)
branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9/_-]//g' | sed 's/^[^a-zA-Z]*//')

# Final validation
if [ -z "$branch_name" ] || [[ "$branch_name" == *" "* ]]; then
    echo "Error: Invalid branch name generated"
    exit 1
fi

echo "Generated branch name: $branch_name"
echo ""

# Create and switch to the new branch
git checkout -b "$branch_name"

if [ $? -eq 0 ]; then
    echo "✓ Successfully created and switched to branch: $branch_name"
else
    echo "✗ Failed to create branch"
    exit 1
fi