<<<<<<< HEAD
# Deploy — Guia de Operação

## 1. Pré-requisitos

| Requisito | Versão mínima | Notas |
|---|---|---|
| Docker | 24.0 | `docker --version` |
| PostgreSQL | 14 | Banco provisionado e acessível a partir do container |
| Conta Anthropic | — | Créditos disponíveis em [console.anthropic.com](https://console.anthropic.com). O cliente é responsável pelos custos de uso diretamente com a Anthropic. |
| Langfuse | — | Opcional. Requer acesso à internet se `LANGFUSE_ENABLED=true`. Em ambientes sem internet, defina `LANGFUSE_ENABLED=false`. |

---

## 2. Configuração das variáveis de ambiente
=======
# FinAnalytics — Deploy

Repositório de implantação do sistema FinAnalytics.  
Contém apenas os arquivos necessários para subir o sistema em produção — sem código-fonte.

---

## Pré-requisitos

| Requisito | Versão mínima |
|-----------|---------------|
| Docker | 24.0 |
| Docker Compose | 2.20 |
| Acesso à internet | Para puxar a imagem do GHCR e conectar à Anthropic |

---

## Instalação

### 1. Clonar este repositório

```bash
git clone https://github.com/ColaboradorLeance/deploy-finanalytics.git
cd deploy-finanalytics
```

### 2. Configurar variáveis de ambiente
>>>>>>> 3d48de3 (feat: repositório de deploy completo e funcional)

```bash
cp .env.example .env
```

<<<<<<< HEAD
Edite `.env` e preencha os campos obrigatórios:

- `DATABASE_URL` — string de conexão PostgreSQL
- `SESSION_SECRET` — string aleatória segura (min. 32 caracteres); gere com:
  ```bash
  openssl rand -base64 48
  ```
- `ANTHROPIC_API_KEY` — chave da API Anthropic

> **Importante:** Nunca commite o arquivo `.env`. Ele está no `.gitignore`.

---

## 2.1 Aplicar migrações de banco de dados

**Obrigatório antes da primeira execução** — ou ao atualizar para uma versão com novas migrações.

```bash
docker run --rm \
  --network <rede-do-postgres> \
  -v "$(pwd):/app" \
  -w /app \
  -e DATABASE_URL="postgresql://user:password@db-host:5432/dbname" \
  node:20-slim \
  sh -c "npx drizzle-kit migrate"
```

Substitua `<rede-do-postgres>` pela rede Docker onde o banco está acessível, e `DATABASE_URL` pelas credenciais reais. O comando é idempotente — pode ser executado em todas as atualizações com segurança.

> **Atenção:** Nunca execute `db:push` apontando para o banco de produção. Use sempre `drizzle-kit migrate` com os arquivos de `migrations/`.

---

## 2.2 Requisito: HTTPS em produção

A aplicação usa cookies de sessão com `Secure: true` e `SameSite: None`. Isso significa que o login e a autenticação só funcionam via **HTTPS**.

Configure um proxy reverso (nginx, Traefik, Caddy) que termine TLS e repasse `X-Forwarded-Proto: https` ao container. Exemplo mínimo com nginx:
=======
Edite o arquivo `.env` e preencha obrigatoriamente:

| Variável | Descrição |
|----------|-----------|
| `DB_PASSWORD` | Senha do banco de dados (crie uma senha forte) |
| `SESSION_SECRET` | String aleatória longa — gere com `openssl rand -base64 48` |
| `ANTHROPIC_API_KEY` | Chave da API Anthropic (console.anthropic.com) |
| `FRONTEND_URL` | URL pública do sistema, ex: `https://app.seudominio.com` |

### 3. (Primeira vez) Autenticar no registro de imagens

```bash
# Solicite o token de acesso à Finanalytics
echo SEU_TOKEN | docker login ghcr.io -u ColaboradorLeance --password-stdin
```

### 4. Subir o sistema

```bash
docker compose up -d
```

O Docker vai:
1. Baixar a imagem da aplicação
2. Subir o banco de dados PostgreSQL
3. Aplicar as migrations automaticamente
4. Iniciar a aplicação

### 5. Verificar

```bash
curl http://localhost:3000/api/health
# {"status":"ok"}
```

---

## Atualização para nova versão

```bash
# Baixa a nova imagem e reinicia apenas o app (banco não é afetado)
docker compose pull app
docker compose up -d app
```

Se a atualização incluir novas migrations:

```bash
# Atualiza o repositório de deploy primeiro
git pull

# Roda as migrations e reinicia
docker compose run --rm migrate
docker compose up -d app
```

---

## Observações importantes

### HTTPS obrigatório

O sistema usa cookies com `Secure: true`. O login **não funciona via HTTP puro**.  
Configure um proxy reverso (nginx, Traefik, Caddy) com certificado SSL antes de colocar em produção.

Exemplo mínimo com nginx:
>>>>>>> 3d48de3 (feat: repositório de deploy completo e funcional)

```nginx
server {
    listen 443 ssl;
    server_name app.seudominio.com;

    ssl_certificate     /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    location / {
        proxy_pass         http://localhost:3000;
        proxy_set_header   Host $host;
<<<<<<< HEAD
        proxy_set_header   X-Real-IP $remote_addr;
=======
>>>>>>> 3d48de3 (feat: repositório de deploy completo e funcional)
        proxy_set_header   X-Forwarded-Proto https;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

<<<<<<< HEAD
---

## 3. Build da imagem

```bash
docker build -t finanalytics:latest .
```

O build é multi-stage. O stage final não contém código-fonte, dependências de desenvolvimento, nem arquivos de configuração sensíveis.

Para gerar uma tag versionada:

```bash
docker build -t finanalytics:1.0.0 .
=======
### Billing Anthropic

O uso de IA é cobrado **diretamente na sua conta Anthropic**.  
A Finanalytics não intermedia nem controla esse custo.

### Dados persistidos

Os dados do banco ficam no volume Docker `postgres_data`.  
Para backup:

```bash
docker exec deploy-finanalytics-db-1 pg_dump -U finanalytics finanalytics > backup.sql
>>>>>>> 3d48de3 (feat: repositório de deploy completo e funcional)
```

---

<<<<<<< HEAD
## 4. Executar o container

```bash
docker run -d \
  --name finanalytics \
  --env-file .env \
  -p 3000:3000 \
  --restart unless-stopped \
  finanalytics:latest
```

> **Regra:** Sempre use `--env-file .env`. Nunca passe segredos via `-e KEY=valor` inline — isso os expõe no histórico do shell e em `docker inspect`.

---

## 5. Verificação

**Healthcheck:**

```bash
curl -f http://localhost:3000/api/health
# Resposta esperada: {"status":"ok"}
```

**Logs esperados na inicialização:**

```
[Observability] Langfuse tracing iniciado          ← se LANGFUSE_ENABLED=true
[Observability] Langfuse tracing desabilitado      ← se LANGFUSE_ENABLED=false
```

**Status do container:**

```bash
docker ps -f name=finanalytics
docker logs finanalytics --tail 50
```

---

## 6. Atualização e encerramento gracioso

**Atualizar para nova versão:**

```bash
docker build -t finanalytics:latest .
docker stop finanalytics
docker rm finanalytics
docker run -d --name finanalytics --env-file .env -p 3000:3000 --restart unless-stopped finanalytics:latest
```

**Encerramento gracioso** (aguarda flush de traces e conexões em aberto):

```bash
docker stop --time 30 finanalytics
```

O processo responde a `SIGTERM` com shutdown ordenado. O timeout padrão do Docker é 10 s; recomendamos 30 s para garantir o flush de telemetria pendente.
=======
## Comandos úteis

```bash
# Ver logs da aplicação
docker compose logs app -f

# Ver logs das migrations
docker compose logs migrate

# Parar tudo
docker compose down

# Parar e apagar o banco (DESTRUTIVO)
docker compose down -v
```
>>>>>>> 3d48de3 (feat: repositório de deploy completo e funcional)
