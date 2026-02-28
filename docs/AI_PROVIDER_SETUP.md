# AI Provider Setup Guide

This guide covers how to configure different AI providers with OpenClaw, including subscription-based services.

## Quick Start

Choose your preferred authentication method:

| Provider           | Best For                   | Setup Method               | Guide                                                     |
| ------------------ | -------------------------- | -------------------------- | --------------------------------------------------------- |
| **GitHub Copilot** | Copilot+ subscribers       | Interactive OAuth          | [See below](#github-copilot-setup)                        |
| **Anthropic**      | Claude Pro/Max subscribers | Interactive OAuth          | [docs/ANTHROPIC_OAUTH_SETUP.md](ANTHROPIC_OAUTH_SETUP.md) |
| **API Keys**       | Pay-per-use, multiple LLMs | Auto-configured by Ansible | [See below](#api-keys-setup)                              |

---

## GitHub Copilot+ Setup

If you have a **GitHub Copilot+** subscription, you can use it with OpenClaw instead of paying per token.

### Prerequisites

- Active GitHub Copilot+ subscription (Individual, Business, or Enterprise)
- GitHub account with Copilot access
- OpenClaw deployed via Proxiclaw

### Configuration

#### Step 1: Configure Provider

**Edit:** `ansible/inventory/group_vars/all.yml`

```yaml
# Use GitHub Copilot+ as primary provider
primary_ai_provider: "copilot"

# Leave API keys empty (will configure interactively)
anthropic_api_key: ""
openai_api_key: ""
```

#### Step 2: Deploy OpenClaw

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

#### Step 3: Configure GitHub Copilot (Interactive)

After deployment, SSH to your VM and run the configuration wizard:

```bash
# SSH to the VM
ssh ubuntu@<vm-ip>

# Run interactive configuration
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
```

#### Step 4: Select Copilot

When prompted:

1. **Select provider:** Choose `Copilot`
2. **Model selection (if prompted):**
   - Some versions may ask you to choose a default model during setup
   - Pick GPT-4o or GPT-4 Turbo for coding (recommended)
   - Don't worry - you can change this anytime later
3. **Authentication will start automatically**
4. **Follow the OAuth flow:**
   - A URL and verification code will be displayed
   - Open https://github.com/login/device in your browser
   - Sign in with your GitHub account (make sure it has Copilot+ access)
   - Enter the verification code shown in the terminal
   - Authorize OpenClaw to access your GitHub Copilot
   - Return to terminal - authentication will complete automatically

> **Note:** The configuration wizard may show you a list of available Copilot models. This is just to set your initial default - you're not enabling/disabling specific models. All models included in your Copilot+ subscription will be available.

#### Step 5: Verify Configuration

```bash
# Check that Copilot auth is configured
cat ~/.openclaw/agents/main/agent/auth-profiles.json

# Should show something like:
# {
#   "version": 1,
#   "profiles": {
#     "copilot:default": {
#       "type": "oauth",
#       "provider": "copilot",
#       "token": "..."
#     }
#   }
# }
```

#### Step 6: Restart OpenClaw

```bash
cd /opt/openclaw
docker compose restart openclaw-gateway
```

#### Step 7: Test

Access OpenClaw in your browser and test:

```
You: Hello! Can you help me write a Python function?
```

OpenClaw should respond using your GitHub Copilot+ subscription.

### Benefits of GitHub Copilot+

- ✅ **Fixed cost:** Flat monthly subscription instead of per-token pricing
- ✅ **No usage anxiety:** Use as much as you need without watching API credits
- ✅ **Multiple models:** Access to various models included in your subscription
- ✅ **Enterprise features:** If you have Enterprise, get additional benefits
- ✅ **Fast:** Generally good performance and rate limits

### Available Models

GitHub Copilot provides access to various models through your subscription.

**How it works:**

- You'll choose **ONE default model** that OpenClaw uses for all conversations
- You can change the default model anytime
- In the OpenClaw UI, you can select different models per conversation if needed

**Typical Copilot+ models (may vary by subscription level):**

- GPT-4 Turbo
- GPT-4o
- GPT-3.5 Turbo
- Claude 3.5 Sonnet (if enabled)
- And others depending on your Copilot tier

**Check what models you have access to:**

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw models list | grep -i copilot
```

**Set your default model after authentication:**

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw

# Example: Set GPT-4o as default
docker compose exec openclaw-gateway openclaw config set agents.defaults.model.primary "copilot/gpt-4o"

# Or GPT-4 Turbo
docker compose exec openclaw-gateway openclaw config set agents.defaults.model.primary "copilot/gpt-4-turbo"

# Restart to apply
docker compose restart openclaw-gateway
```

> **💡 Tip:** Start with GPT-4o or GPT-4 Turbo. These are the most capable models for coding. You can switch anytime based on your needs.

**Using different models per conversation:**

Once authenticated, you can select different models in the OpenClaw web UI:

1. Start a new conversation
2. Click the model selector (usually shows current default)
3. Choose any Copilot model you have access to
4. That conversation will use the selected model

### Copilot+ FAQ

**Q: Do all Copilot models get used automatically?**
A: No. You choose ONE default model that OpenClaw uses. You can manually switch models per conversation in the UI.

**Q: Which model should I pick as default?**
A: For coding, recommend **GPT-4o** or **GPT-4 Turbo**. These are the most capable for complex tasks. Use the model selector in the UI to try others for specific tasks.

**Q: Does using Copilot+ with OpenClaw use my request quota?**
A: Yes, requests count toward your Copilot subscription limits (e.g., 50-100 requests/month for Individual, unlimited for Enterprise). However, it's still much better than paying per token with API keys.

**Q: Can I use multiple providers at once (e.g., Copilot + Claude API)?**
A: Yes! See [Mixed Configuration](#mixed-configuration-subscription--api-keys) below.

**Q: What if I run out of Copilot requests?**
A: Configure fallback API keys. OpenClaw can automatically fall back to API-based models when your Copilot quota is reached.

---

## Anthropic OAuth Setup (Claude Pro/Max)

See dedicated guide: [ANTHROPIC_OAUTH_SETUP.md](ANTHROPIC_OAUTH_SETUP.md)

---

## API Keys Setup

For pay-per-use with multiple providers, use API keys.

### Configuration

**Edit:** `ansible/inventory/group_vars/all.yml`

```yaml
# Use API keys for all providers
primary_ai_provider: "api_keys_only"
anthropic_auth_method: "api_key"

# Add your API keys
anthropic_api_key: "sk-ant-your-key-here"
openai_api_key: "sk-proj-your-key-here"

# Set default model
openclaw_default_model: "anthropic/claude-sonnet-4-6"
```

### Deploy

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

That's it! API keys are auto-configured by Ansible.

### Supported API Key Providers

- **Anthropic:** Claude models (API key from https://console.anthropic.com)
- **OpenAI:** GPT models (API key from https://platform.openai.com)
- **Google:** Gemini models (API key from Google AI Studio)
- **xAI:** Grok models (API key from xAI)
- **Mistral:** Mistral models (API key from Mistral platform)
- **And many more:** See OpenClaw documentation for full list

---

## Mixed Configuration (Subscription + API Keys)

You can use a subscription for your primary provider and API keys for others.

**Example:** GitHub Copilot+ for main work, Claude API for specific tasks

```yaml
# Use Copilot+ as primary (requires interactive setup)
primary_ai_provider: "copilot"

# Add API keys for fallback/specific use cases
anthropic_auth_method: "api_key"
anthropic_api_key: "sk-ant-your-key-here"
openai_api_key: "sk-proj-your-key-here"
```

After deployment, configure both:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model

# Configure Copilot via OAuth (first provider)
# Then add API keys for other providers
```

---

## Switching Providers

### Switch from API Keys to Copilot+

1. **Update configuration:**

   ```yaml
   primary_ai_provider: "copilot"
   anthropic_api_key: "" # Clear API keys if not needed as fallback
   ```

2. **Re-run Ansible:**

   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/site.yml
   ```

3. **Configure Copilot OAuth** (see steps above)

### Switch from Copilot+ to API Keys

1. **Update configuration:**

   ```yaml
   primary_ai_provider: "api_keys_only"
   anthropic_api_key: "sk-ant-your-key-here"
   anthropic_auth_method: "api_key"
   ```

2. **Re-run Ansible:**
   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/site.yml
   ```

---

## Troubleshooting

### OAuth Flow Doesn't Complete

**Issue:** Device code verification page doesn't work

**Solutions:**

1. **Check you're signed in:** Make sure you're logged into the correct GitHub/Anthropic account
2. **Check subscription:** Verify your subscription is active
3. **Try incognito mode:** Sometimes browser cookies interfere
4. **Copy the full URL:** Copy and paste the complete authorization URL

### "Invalid Subscription" or "Access Denied"

**Issue:** Authentication completes but OpenClaw can't use the service

**Solutions:**

1. **Verify subscription is active:**
   - GitHub Copilot: Check at https://github.com/settings/copilot
   - Claude: Check at https://claude.ai/settings

2. **Check account permissions:**
   - Make sure the account you authenticated with actually has the subscription
   - For Enterprise, check with your admin

3. **Re-authenticate:**
   ```bash
   rm ~/.openclaw/agents/main/agent/auth-profiles.json
   cd /opt/openclaw && docker compose restart openclaw-gateway
   # Run configuration wizard again
   ```

### Token Expired

**Issue:** OpenClaw stops working after some time

**Solution:** OAuth tokens expire. Re-run the configuration:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
# Complete the OAuth flow again
docker compose restart openclaw-gateway
```

### Multiple Providers Not Working

**Issue:** Only one provider works at a time

**Solution:** In the configure wizard, add all providers you want:

```bash
docker compose exec openclaw-gateway openclaw configure --section model
# Add first provider (e.g., Copilot via OAuth)
# Exit and re-run to add more:
docker compose exec openclaw-gateway openclaw configure --section model
# Add second provider (e.g., Anthropic via API key)
```

### Can't Access OAuth URL from Headless Server

**Issue:** VM has no browser, can't open OAuth URLs

**Solutions:**

1. **Port forwarding (recommended):**

   ```bash
   # Create SSH tunnel from local machine
   ssh -L 18789:localhost:18789 ubuntu@<vm-ip>
   ```

2. **Copy URL to any browser:** Copy the OAuth/device code URL and open it on any computer where you're logged in

---

## Cost Comparison

| Provider              | Typical Cost            | Best For                    |
| --------------------- | ----------------------- | --------------------------- |
| **GitHub Copilot+**   | $10-19/month flat       | Heavy daily usage           |
| **Claude Pro**        | $20/month flat          | Heavy Claude usage          |
| **API Keys (Claude)** | ~$3-15 per 1M tokens    | Moderate/sporadic usage     |
| **API Keys (OpenAI)** | ~$0.15-60 per 1M tokens | Varies by model             |
| **API Keys (Haiku)**  | ~$0.80-4 per 1M tokens  | Budget-friendly heavy usage |

**Rule of thumb:**

- **Heavy daily use:** Subscription (Copilot+ or Claude Pro)
- **Sporadic use:** API keys
- **Mixed use:** Subscription for primary + API keys for fallback

---

## Additional Configuration

### Set Default Model After Setup

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw config set agents.defaults.model.primary "gpt-4o"
docker compose restart openclaw-gateway
```

### Check Authentication Status

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw auth status
```

### List Available Models

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw models list
```

---

## Security Notes

- OAuth tokens are stored in `~/.openclaw/agents/main/agent/auth-profiles.json`
- This file has `600` permissions (only your user can read)
- API keys are stored in the same file
- The backup role **excludes** this file for security
- Never commit or share `auth-profiles.json`
- Tokens may need periodic renewal (OAuth providers handle this automatically)

---

## See Also

- [Anthropic OAuth Setup](ANTHROPIC_OAUTH_SETUP.md) - Detailed Claude Pro/Max setup
- [Getting Started](GETTING_STARTED.md) - Using OpenClaw
- [Common Commands](COMMON_COMMANDS.md) - Quick reference
- [Cost Optimization](COST_OPTIMIZATION.md) - Reduce API costs
