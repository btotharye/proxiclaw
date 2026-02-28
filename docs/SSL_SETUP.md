# SSL/TLS Setup for OpenClaw

This guide covers different ways to enable HTTPS for secure access to OpenClaw on your local network.

## Option 1: Auto-Generated Self-Signed Certificate (Easiest)

**Pros:** Automatic, no setup required  
**Cons:** Browser security warnings on first access

### Setup

1. Edit `ansible/inventory/group_vars/all.yml`:

   ```yaml
   openclaw_enable_tls: true
   ```

2. Run Ansible playbook:

   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/site.yml --tags openclaw
   ```

3. Access at `https://192.168.30.118:18789`
4. Accept the browser security warning (one-time)

## Option 2: mkcert (Best for Development)

**Pros:** No browser warnings, locally-trusted certificates  
**Cons:** Requires initial setup on your Mac

### Setup on Mac

1. **Install mkcert:**

   ```bash
   brew install mkcert nss  # nss is for Firefox support
   mkcert -install
   ```

2. **Generate certificates for your VM:**

   ```bash
   # Create certs directory
   mkdir -p ~/openclaw-certs
   cd ~/openclaw-certs

   # Generate certificate for your VM's IP
   mkcert 192.168.30.118 localhost 127.0.0.1 ::1

   # This creates two files:
   # - 192.168.30.118+3.pem (certificate)
   # - 192.168.30.118+3-key.pem (private key)
   ```

3. **Copy certificates to VM:**

   ```bash
   scp 192.168.30.118+3.pem ubuntu@192.168.30.118:~/openclaw-cert.pem
   scp 192.168.30.118+3-key.pem ubuntu@192.168.30.118:~/openclaw-key.pem

   # SSH and secure the files
   ssh ubuntu@192.168.30.118
   mkdir -p ~/.openclaw/certs
   mv ~/openclaw-cert.pem ~/.openclaw/certs/
   mv ~/openclaw-key.pem ~/.openclaw/certs/
   chmod 600 ~/.openclaw/certs/openclaw-key.pem
   chmod 644 ~/.openclaw/certs/openclaw-cert.pem
   ```

4. **Configure Ansible:**

   Edit `ansible/inventory/group_vars/all.yml`:

   ```yaml
   openclaw_enable_tls: true
   openclaw_tls_cert_path: "/home/ubuntu/.openclaw/certs/openclaw-cert.pem"
   openclaw_tls_key_path: "/home/ubuntu/.openclaw/certs/openclaw-key.pem"
   ```

5. **Deploy:**

   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/site.yml --tags openclaw
   ```

6. **Access:** `https://192.168.30.118:18789` (no warnings!)

### Trust on Other Devices

To access from iOS/Android or other computers:

**On the VM:**

```bash
# Get the root CA certificate
mkcert -CAROOT
# Copy rootCA.pem to your device and install it
```

**iOS:** Settings → General → VPN & Device Management → Install Profile  
**Android:** Settings → Security → Encryption & credentials → Install certificate

## Option 3: Tailscale (Most Secure)

**Pros:** Zero-configuration, encrypted mesh network, works anywhere  
**Cons:** Requires Tailscale account (free tier available)

### Setup

1. **Install Tailscale on VM:**

   ```bash
   ssh ubuntu@192.168.30.118
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

2. **Install Tailscale on your Mac:**

   ```bash
   brew install tailscale
   sudo tailscale up
   ```

3. **Configure OpenClaw for Tailscale:**

   Edit `~/.openclaw/openclaw.json` on the VM:

   ```json
   {
     "gateway": {
       "mode": "local",
       "bind": "tailnet",
       "port": 18789,
       "tailscale": {
         "mode": "serve"
       }
     }
   }
   ```

4. **Restart OpenClaw:**

   ```bash
   cd /opt/openclaw
   docker compose restart openclaw-gateway
   ```

5. **Access via Tailscale:**
   - Find your VM's Tailscale hostname in the Tailscale admin panel
   - Access at `https://[tailscale-hostname]:18789`
   - OR use the Tailscale IP (typically starts with 100.x.x.x)

### Tailscale Funnel (Public Internet Access)

To expose OpenClaw to the internet securely:

```json
{
  "gateway": {
    "tailscale": {
      "mode": "funnel"
    }
  }
}
```

This creates a public HTTPS URL while keeping your server behind Tailscale's secure tunnel.

## Option 4: Reverse Proxy with Let's Encrypt (Production)

**Pros:** Free, trusted certificates, production-ready  
**Cons:** Requires domain name, more complex setup

### Requirements

- Domain name (e.g., `openclaw.yourdomain.com`)
- A records pointing to your public IP
- Port forwarding configured on your router (80, 443 → VM)

### Setup with Traefik

1. **Install Traefik on VM:**

   ```bash
   ssh ubuntu@192.168.30.118
   mkdir -p ~/traefik
   cd ~/traefik
   ```

2. **Create `docker-compose.yml`:**

   ```yaml
   version: "3"
   services:
     traefik:
       image: traefik:v2.10
       container_name: traefik
       restart: unless-stopped
       ports:
         - "80:80"
         - "443:443"
       volumes:
         - /var/run/docker.sock:/var/run/docker.sock:ro
         - ./traefik.yml:/traefik.yml:ro
         - ./acme.json:/acme.json
       environment:
         - CLOUDFLARE_EMAIL=your@email.com
         - CLOUDFLARE_API_KEY=your_api_key
   ```

3. **Create `traefik.yml`:**

   ```yaml
   entryPoints:
     web:
       address: ":80"
       http:
         redirections:
           entryPoint:
             to: websecure
             scheme: https
     websecure:
       address: ":443"

   certificatesResolvers:
     letsencrypt:
       acme:
         email: your@email.com
         storage: /acme.json
         httpChallenge:
           entryPoint: web
   ```

4. **Update OpenClaw docker-compose.yml** to add Traefik labels

5. **Start Traefik:**
   ```bash
   touch acme.json && chmod 600 acme.json
   docker compose up -d
   ```

## Comparison

| Method        | Security  | Setup Time | Browser Warnings | Remote Access   | Cost          |
| ------------- | --------- | ---------- | ---------------- | --------------- | ------------- |
| Self-Signed   | Good      | 1 min      | Yes              | LAN only        | Free          |
| mkcert        | Excellent | 10 min     | No               | LAN only        | Free          |
| Tailscale     | Excellent | 15 min     | No               | Anywhere        | Free tier     |
| Let's Encrypt | Excellent | 30+ min    | No               | Public internet | Free + domain |

## Recommendation

- **Just testing locally on your Mac:** Self-signed (Option 1)
- **Regular use on LAN, multiple devices:** mkcert (Option 2) ✅ **BEST**
- **Access from anywhere securely:** Tailscale (Option 3)
- **Full production deployment:** Let's Encrypt with reverse proxy (Option 4)

## Security Notes

1. **Device Auth:** With HTTPS enabled, you can remove `dangerouslyDisableDeviceAuth: true` from the config for better security
2. **Authentication:** Consider enabling token or password auth by removing `auth.mode` from config
3. **Firewall:** Keep UFW enabled and only open necessary ports
4. **Updates:** Regularly update OpenClaw and system packages

## Testing Your SSL Setup

```bash
# Check certificate
curl -vI https://192.168.30.118:18789

# Test from browser DevTools console
fetch('https://192.168.30.118:18789')
  .then(r => console.log('Secure connection working!'))
```

## Troubleshooting

### "Connection not secure" warning

- Expected with self-signed certs
- Click "Advanced" → "Proceed anyway" (one-time)

### "ERR_CERT_AUTHORITY_INVALID"

- mkcert root CA not installed
- Run: `mkcert -install`

### OpenClaw won't start with TLS

Check logs: `docker compose logs openclaw-gateway`
Common issues:

- Wrong cert/key paths
- Permission denied on key file (run `chmod 600`)
- Port 18789 already in use
