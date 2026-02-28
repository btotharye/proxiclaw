# Anthropic OAuth Setup (Claude Pro/Max Subscription)

If you have a **Claude Pro** or **Claude Max** subscription, you can use OAuth to authenticate OpenClaw instead of using pay-per-use API credits.

> ⚠️ **Important:** OAuth support for Anthropic may vary by OpenClaw version. If you don't see an OAuth option when selecting Anthropic in the configuration wizard, see the [Troubleshooting section](#oauth-option-not-available) below.

## Checking OAuth Availability

First, verify if your OpenClaw version supports Anthropic OAuth:

**Quick Check (Automated Script):**

```bash
# From your local machine
cd proxiclaw
./scripts/check-oauth-support.sh <vm-ip>

# Example:
./scripts/check-oauth-support.sh 192.168.30.118
```

This script will check your OpenClaw version and show you what authentication options are available.

**Manual Check:**

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw

# Check OpenClaw version
docker compose exec openclaw-gateway openclaw --version

# Try the configuration wizard and look for OAuth option
docker compose exec openclaw-gateway openclaw configure --section model
# When you select "Anthropic", check if you see "OAuth" as an authentication option
```

If you only see "setup-token + API key" without an OAuth option, OAuth may not be available in your version. See [Alternatives](#alternatives-to-oauth) below.

## Prerequisites

- Active Claude Pro or Claude Max subscription
- OpenClaw deployed via Proxiclaw
- SSH access to your OpenClaw VM

## Configuration

### Step 1: Set Authentication Method

Before deploying, configure Ansible to use OAuth instead of API keys:

**Edit:** `ansible/inventory/group_vars/all.yml`

```yaml
# Set to "oauth" to use your Claude subscription
anthropic_auth_method: "oauth"

# Leave API key empty when using OAuth
anthropic_api_key: ""
```

### Step 2: Deploy OpenClaw

Deploy normally with Ansible:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

### Step 3: Run Interactive OAuth Configuration

After deployment, SSH to your VM and run the interactive configuration:

```bash
# SSH to the VM
ssh ubuntu@<vm-ip>

# Run OpenClaw configuration wizard
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
```

### Step 4: Select OAuth Authentication

When prompted:

1. **Select provider:** Choose `Anthropic`
2. **Select authentication method:** Choose `OAuth (Claude Pro/Max)`
3. **Follow the OAuth flow:**
   - A URL will be displayed
   - Open the URL in your browser
   - Sign in with your Anthropic account (the one with Pro/Max subscription)
   - Authorize OpenClaw
   - Return to the terminal - the token will be saved automatically

### Step 5: Verify Configuration

Check that OAuth is configured correctly:

```bash
# Check auth profiles
cat ~/.openclaw/agents/main/agent/auth-profiles.json

# Should show something like:
# {
#   "version": 1,
#   "profiles": {
#     "anthropic:default": {
#       "type": "oauth",
#       "provider": "anthropic",
#       "token": "..."
#     }
#   }
# }
```

### Step 6: Restart OpenClaw

```bash
cd /opt/openclaw
docker compose restart openclaw-gateway
```

### Step 7: Test

Access OpenClaw in your browser and try sending a message:

```
You: Hello! What subscription level am I using?
```

OpenClaw should respond using your Claude Pro/Max subscription instead of API credits.

## Benefits of OAuth vs API Keys

| Feature          | OAuth (Pro/Max)            | API Keys             |
| ---------------- | -------------------------- | -------------------- |
| **Cost**         | Fixed monthly subscription | Pay per token        |
| **Usage Limits** | Higher limits for Pro/Max  | Based on API tier    |
| **Model Access** | All models included        | All models (if paid) |
| **Best For**     | Heavy daily usage          | Sporadic/light usage |
| **Rate Limits**  | Subscription tier limits   | API tier limits      |
| **Requires**     | Active subscription        | API credits/billing  |

## Fallback to API Keys

You can configure both OAuth (for Anthropic) and API keys (for other providers):

**`ansible/inventory/group_vars/all.yml`:**

```yaml
# Use OAuth for Claude (subscription)
anthropic_auth_method: "oauth"
anthropic_api_key: ""

# Use API keys for other providers (pay-per-use)
openai_api_key: "sk-proj-your-key-here"
```

After deployment, run the configuration wizard once more to keep both:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
# Select Anthropic → OAuth for Claude
# Select OpenAI → API Key and enter your key
```

## Switching Between Auth Methods

### From API Key to OAuth

1. Update `all.yml`: Set `anthropic_auth_method: "oauth"`
2. Re-run Ansible playbook
3. Run OAuth configuration (Step 3 above)

### From OAuth to API Key

1. Update `all.yml`:
   ```yaml
   anthropic_auth_method: "api_key"
   anthropic_api_key: "sk-ant-your-key-here"
   ```
2. Re-run Ansible playbook
3. Restart OpenClaw

## Troubleshooting

### OAuth Option Not Available

**Issue:** When selecting Anthropic in the configuration wizard, only "setup-token + API key" appears, no OAuth option

**Possible Causes:**

1. **OpenClaw version doesn't support Anthropic OAuth:** OAuth support may have been added/removed in different versions
2. **Feature not enabled:** OAuth might require specific build flags or configuration
3. **Provider changed:** Anthropic may have changed their authentication methods

**Investigation Steps:**

```bash
# Check OpenClaw version and release notes
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw --version

# Check the OpenClaw repository for OAuth documentation
# Visit: https://github.com/openclaw/openclaw/tree/main/docs

# Look at the actual provider options in the code
docker compose exec openclaw-gateway openclaw configure --section model
# Document exactly what options you see for Anthropic

# Check if there are environment variables needed
docker compose exec openclaw-gateway env | grep -i oauth
docker compose exec openclaw-gateway env | grep -i anthropic
```

**Alternatives if OAuth is not available:**

1. **Use GitHub Copilot+** instead (if you have a subscription) - see [AI_PROVIDER_SETUP.md](AI_PROVIDER_SETUP.md#github-copilot-setup)
2. **Use API keys** with Claude API - Standard API access with per-token pricing
3. **Contact OpenClaw community** - Check their Discord/GitHub for OAuth support status

### OAuth Flow Doesn't Start

**Issue:** The OAuth URL doesn't appear

**Solution:**

```bash
# Check logs for errors
docker logs openclaw-openclaw-gateway-1 --tail 50

# Ensure OpenClaw is up to date
cd /opt/openclaw
docker compose pull
docker compose up -d
```

### "Invalid Subscription" Error

**Issue:** OAuth completes but OpenClaw says subscription is invalid

**Solution:**

- Verify your Claude Pro/Max subscription is active at https://claude.ai
- Check that you're signed in with the correct Anthropic account
- Try clearing OAuth config and re-running:
  ```bash
  rm ~/.openclaw/agents/main/agent/auth-profiles.json
  cd /opt/openclaw && docker compose restart openclaw-gateway
  # Re-run configuration wizard
  ```

### Token Expired

**Issue:** OpenClaw stops working after some time

**Solution:** OAuth tokens can expire. Re-run the OAuth flow:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
# Complete OAuth flow again
docker compose restart openclaw-gateway
```

### Can't Access VM Browser for OAuth

**Issue:** OAuth requires opening a browser, but your VM is headless

**Solutions:**

1. **Port Forward (Recommended):**

   ```bash
   # On your local machine, create an SSH tunnel
   ssh -L 18789:localhost:18789 ubuntu@<vm-ip>

   # Keep this terminal open
   # In another terminal, complete OAuth:
   ssh ubuntu@<vm-ip>
   cd /opt/openclaw
   docker compose exec openclaw-gateway openclaw configure --section model
   ```

   When the OAuth URL appears, you can open it on your local machine.

2. **Use the Authorization URL Directly:**

   Copy the full OAuth URL from the terminal and paste it into a browser on any machine where you're logged into claude.ai.

## Alternatives to OAuth

If Anthropic OAuth is not available in your OpenClaw version, consider these alternatives:

### 1. GitHub Copilot+ (Recommended Alternative)

If you have a GitHub Copilot+ subscription, this is the easiest subscription-based alternative:

```yaml
# In ansible/inventory/group_vars/all.yml
primary_ai_provider: "copilot"
```

See full setup: [AI_PROVIDER_SETUP.md](AI_PROVIDER_SETUP.md#github-copilot-setup)

**Benefits:**

- ✅ Similar monthly subscription model ($10-19/month)
- ✅ Confirmed OAuth support in OpenClaw
- ✅ Good for coding tasks
- ✅ Multiple models included

### 2. Claude API Keys (Pay-per-use)

Use Claude via standard API keys instead of OAuth:

```yaml
# In ansible/inventory/group_vars/all.yml
primary_ai_provider: "api_keys_only"
anthropic_auth_method: "api_key"
anthropic_api_key: "sk-ant-your-key-here"
openclaw_default_model: "anthropic/claude-sonnet-4-6"
```

**Pros:**

- ✅ Definitely works with current OpenClaw
- ✅ Simple API key setup
- ✅ Access to all Claude models

**Cons:**

- ❌ Pay per token (can be expensive for heavy use)
- ❌ Need to manage API credits

**Cost estimate:** ~$3-15 per 1M tokens (depends on model)

### 3. Mixed Approach

Use Copilot+ for daily work, Claude API as fallback:

```yaml
primary_ai_provider: "copilot"
anthropic_api_key: "sk-ant-your-key-here" # Fallback
```

This gives you the best of both worlds - subscription for heavy use, API access for specific Claude features.

## Additional Configuration

### Set Default Model After OAuth

After OAuth is configured, you may want to set a specific default model:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw config set agents.defaults.model.primary "anthropic/claude-sonnet-4-6"
docker compose restart openclaw-gateway
```

### Check OAuth Token Status

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw auth status
```

## Security Notes

- OAuth tokens are stored in `~/.openclaw/agents/main/agent/auth-profiles.json`
- This file has `600` permissions (only your user can read it)
- The OpenClaw backup role **excludes** `auth-profiles.json` from backups for security
- Never commit or share `auth-profiles.json`

## See Also

- [Getting Started Guide](GETTING_STARTED.md)
- [Common Commands](COMMON_COMMANDS.md)
- [Cost Optimization](COST_OPTIMIZATION.md)
