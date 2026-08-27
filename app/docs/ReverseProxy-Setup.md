# Reverse Proxy Setup Guide

Business Central's `HttpClient` requires HTTPS with a publicly trusted certificate. Since Ollama (and most local LLM servers) only serve HTTP, you need a reverse proxy to terminate TLS and optionally enforce API key authentication.

---

## Architecture

```
BC Cloud/On-Prem  ──HTTPS──►  Reverse Proxy  ──HTTP──►  Ollama/vLLM
                              (public IP/DNS)             (LAN: 192.168.x.x:11434)
                              TLS + API key auth
```

The BC extension sends requests to:
- `POST {base_url}/v1/chat/completions` — Chat completions
- `GET {base_url}/v1/models` — Model listing

The API key is sent as the `x-api-key` HTTP header.

---

## Option 1: Caddy (Recommended)

Caddy automatically provisions and renews Let's Encrypt certificates.

### Prerequisites
- A public DNS record pointing to your server (e.g., `llm.yourdomain.com`)
- Port 443 open on your firewall
- Docker (or Caddy binary installed)

### Docker Compose

```yaml
services:
  caddy:
    image: caddy:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

### Caddyfile

```caddyfile
llm.yourdomain.com {
    # Require API key on all requests
    @no_key {
        not header x-api-key YOUR_SECRET_API_KEY
    }
    respond @no_key 401

    reverse_proxy 192.168.16.241:11434
}
```

Replace:
- `llm.yourdomain.com` with your actual domain
- `YOUR_SECRET_API_KEY` with a strong random value (e.g., `openssl rand -hex 32`)
- `192.168.16.241:11434` with your Ollama server's LAN address

### Generate a Strong API Key

```bash
openssl rand -hex 32
# Example output: sk-llm-a7b3c9d1e5f2g8h4i6j0k2l4m6n8o0p2
```

### Verify

```powershell
# Should return 401
Invoke-RestMethod -Uri "https://llm.yourdomain.com/v1/models"

# Should return model list
Invoke-RestMethod -Uri "https://llm.yourdomain.com/v1/models" -Headers @{"x-api-key"="YOUR_SECRET_API_KEY"}
```

---

## Option 2: nginx

### Prerequisites
- nginx installed
- Let's Encrypt certificate (via certbot)

### nginx Configuration

```nginx
server {
    listen 443 ssl;
    server_name llm.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/llm.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/llm.yourdomain.com/privkey.pem;

    # API key validation
    set $api_key "YOUR_SECRET_API_KEY";

    if ($http_x_api_key != $api_key) {
        return 401;
    }

    location / {
        proxy_pass http://192.168.16.241:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        # LLM responses can be large and slow
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_buffering off;
    }
}

server {
    listen 80;
    server_name llm.yourdomain.com;
    return 301 https://$host$request_uri;
}
```

### Obtain Certificate

```bash
sudo certbot certonly --nginx -d llm.yourdomain.com
```

---

## Option 3: Traefik

### docker-compose.yml

```yaml
services:
  traefik:
    image: traefik:v3
    command:
      - "--entryPoints.web.address=:80"
      - "--entryPoints.websecure.address=:443"
      - "--certificatesResolvers.letsencrypt.acme.email=you@yourdomain.com"
      - "--certificatesResolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint=web"
      - "--providers.file.filename=/etc/traefik/dynamic.yml"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./letsencrypt:/letsencrypt
      - ./dynamic.yml:/etc/traefik/dynamic.yml
```

### dynamic.yml

```yaml
http:
  routers:
    llm:
      rule: "Host(`llm.yourdomain.com`)"
      entryPoints: ["websecure"]
      tls:
        certResolver: letsencrypt
      middlewares: ["api-key-check"]
      service: ollama

  middlewares:
    api-key-check:
      headers:
        customRequestHeaders:
          X-Check: "true"
      # Traefik doesn't have native header-value auth;
      # use the plugin traefik-api-key or a ForwardAuth service

  services:
    ollama:
      loadBalancer:
        servers:
          - url: "http://192.168.16.241:11434"
```

> **Note:** Traefik has no built-in header-value check. Use the [traefik-api-key plugin](https://plugins.traefik.io/plugins/62947354108ecc83915d7784/api-key) or a ForwardAuth middleware.

---

## Option 4: Azure Application Gateway / Front Door

For organizations running Ollama on an Azure VM or with a site-to-site VPN:

1. Create an Azure Application Gateway or Front Door with a custom domain and managed certificate.
2. Add a backend pool pointing to your Ollama server's private IP.
3. Add a WAF custom rule to validate the `x-api-key` header.
4. Set the health probe to `GET /api/tags` (Ollama's tag endpoint).

---

## Ollama Configuration

### Enable Network Access

By default, Ollama only listens on `127.0.0.1`. To allow connections from the reverse proxy:

**macOS (LaunchAgent):**
```bash
launchctl setenv OLLAMA_HOST 0.0.0.0
# Restart Ollama
```

**Linux (systemd):**
```bash
sudo systemctl edit ollama
# Add under [Service]:
# Environment="OLLAMA_HOST=0.0.0.0"
sudo systemctl restart ollama
```

**Docker:**
```bash
docker run -d -p 11434:11434 ollama/ollama
```

### Keep Model Loaded

To avoid cold-start delays (60–90 seconds), configure Ollama to never unload:

```bash
# macOS LaunchAgent or environment
export OLLAMA_KEEP_ALIVE=-1
```

### Recommended Models for Tool Calling

| Model | Command | Tool Calling | Notes |
|-------|---------|:---:|-------|
| qwen3:8b | `ollama pull qwen3:8b` | Excellent | Best balance of speed and quality on 16GB |
| qwen2.5:14b | `ollama pull qwen2.5:14b` | Excellent | Needs 16GB+, stronger reasoning |
| llama3.1:8b | `ollama pull llama3.1:8b` | Fair | 128K context, less reliable function calls |

---

## Business Central Configuration

After the reverse proxy is running, create an MCP Chat Role:

| Field | Value |
|-------|-------|
| **Code** | `OLLAMA` (or any identifier) |
| **Description** | Ollama (Self-Hosted) |
| **Chat Provider** | Custom LLM |
| **Base URL** | `https://llm.yourdomain.com` |
| **Model** | `qwen3:8b` (select from Model lookup or type directly) |
| **Timeout Seconds** | 300 (5 minutes — increase for cold starts) |
| **Max Tokens** | 8192 (or higher for complex responses) |

Enter the API key (the key defined in your reverse proxy config) via the chat UI's API Key prompt, or save it as a shared Service Key.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Could not reach the LLM API" | BC cannot connect to the endpoint | Verify DNS, firewall, and TLS certificate |
| 401 Unauthorized | Wrong API key | Check the key matches your proxy config |
| Timeout after 300s | Model cold-loading | Set `OLLAMA_KEEP_ALIVE=-1`; increase timeout |
| "Received an invalid response" | Ollama returned non-JSON | Check Ollama logs; ensure model is loaded |
| Certificate error | Self-signed cert | Use Let's Encrypt or a publicly trusted CA |
| Model lookup empty | `/v1/models` not supported | Ollama supports this natively; check proxy path |
