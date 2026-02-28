#!/bin/bash
# OpenClaw OAuth Support Investigation Script
# This script helps determine if Anthropic OAuth is available in your OpenClaw version

set -e

VM_IP="${1:-}"

if [ -z "$VM_IP" ]; then
    echo "Usage: $0 <vm-ip>"
    echo "Example: $0 192.168.30.118"
    exit 1
fi

echo "=================================================="
echo "OpenClaw OAuth Support Investigation"
echo "=================================================="
echo ""

echo "1. Checking OpenClaw version..."
ssh ubuntu@$VM_IP "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw --version" || echo "Failed to get version"
echo ""

echo "2. Checking available providers..."
echo "Starting configuration wizard - Type Ctrl+C when you see the provider list"
echo "Look for 'Anthropic' and note what authentication options are shown"
echo ""
ssh ubuntu@$VM_IP "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw configure --section model" || true
echo ""

echo "3. Checking environment for OAuth-related variables..."
ssh ubuntu@$VM_IP "cd /opt/openclaw && docker compose exec openclaw-gateway env | grep -iE '(oauth|anthropic|claude)'" || echo "No OAuth environment variables found"
echo ""

echo "4. Checking current auth configuration..."
ssh ubuntu@$VM_IP "cat ~/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null" || echo "No auth profiles configured yet"
echo ""

echo "5. Checking OpenClaw configuration..."
ssh ubuntu@$VM_IP "cat ~/.openclaw/openclaw.json | jq '.agents.defaults' 2>/dev/null" || echo "No default agent configuration found"
echo ""

echo "=================================================="
echo "Investigation Complete"
echo "=================================================="
echo ""
echo "What to look for:"
echo "- In step 2, did you see 'OAuth' as an option for Anthropic?"
echo "- If yes: OAuth is supported, follow docs/ANTHROPIC_OAUTH_SETUP.md"
echo "- If no: Consider alternatives in docs/AI_PROVIDER_SETUP.md"
echo "  * GitHub Copilot+ (recommended if you have subscription)"
echo "  * Claude API Keys (pay-per-use)"
echo ""
echo "For more help, see:"
echo "- docs/ANTHROPIC_OAUTH_SETUP.md"
echo "- docs/AI_PROVIDER_SETUP.md"
