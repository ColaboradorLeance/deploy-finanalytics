# FinAnalytics — Guia de Deploy

Sistema SaaS de análise financeira para empresas brasileiras.
Este repositório contém apenas os arquivos de infraestrutura — sem código-fonte.

---

## Escolha seu modo de instalação

| Situação | Modo recomendado |
|----------|-----------------|
| Servidor simples, primeira instalação | [Docker Compose](#modo-1--docker-compose) — banco de dados incluído, tudo configurado em um comando |
| Kubernetes, Docker Swarm ou banco de dados próprio | [Somente a imagem](#modo-2--somente-a-imagem) — integre na sua infraestrutura |

---

## Modo 1 — Docker Compose

Ideal para instalações simples. Sobe banco de dados, migrations e aplicação com um único comando.

### Pré-requisitos

| Requisito | Versão mínima | Como verificar |
|-----------|---------------|----------------|
| Docker | 24.0 | `docker --version` |
| Docker Compose | 2.20 | `docker compose version` |
| Acesso à internet | — | Para baixar a imagem e conectar à Anthropic |

### Passo 1 — Clonar este repositório

```bash
git clone https://github.com/ColaboradorLeance/deploy-finanalytics.git
cd deploy-finanalytics
```

### Passo 2 — Configurar o ambiente

```bash
cp .env.example .env
```

Abra o `.env` e preencha os campos. Os obrigatórios são:

| Campo | Descrição |
|-------|-----------|
| `DB_PASSWORD` | Senha do banco — use algo forte, ex: `openssl rand -base64 16` |
| `SESSION_SECRET` | Chave de sessão — gere com `openssl rand -base64 48` |
| `CLIENT_ADMIN_EMAIL` | Email do primeiro usuário administrador |
| `CLIENT_ADMIN_PASSWORD` | Senha inicial do administrador |
| `ANTHROPIC_API_KEY` | Chave da API Anthropic — obtenha em [console.anthropic.com](https://console.anthropic.com) |
| `FRONTEND_URL` | URL pública do sistema, ex: `https://app.seudominio.com` |

> **Atenção ao editar o .env no Windows:** use o VS Code, não o Notepad. O Notepad adiciona caracteres invisíveis (`\r`) que corrompem as chaves de API.

### Passo 3 — Autenticar no registro de imagens

A imagem é privada. Solicite o token de acesso à Finanalytics e autentique:

```bash
echo SEU_TOKEN | docker login ghcr.io -u ColaboradorLeance --password-stdin
```

> Só precisa fazer isso uma vez por máquina.

### Passo 4 — Subir o sistema

```bash
docker compose up -d
```

O Docker executa automaticamente nesta ordem:
1. Inicia o banco de dados PostgreSQL
2. Aguarda o banco estar pronto
3. Aplica todas as migrations do banco
4. Inicia a aplicação
5. Inicia o proxy nginx

### Passo 5 — Verificar

```bash
curl http://localhost:3000/api/health
# Resposta esperada: {"status":"ok"}
```

Acesse `http://localhost:3000` — a tela de login deve aparecer.

Entre com o email e senha definidos em `CLIENT_ADMIN_EMAIL` e `CLIENT_ADMIN_PASSWORD`.

---

## Modo 2 — Somente a imagem

Para quem já tem banco de dados PostgreSQL, proxy reverso e quer integrar o container na própria infraestrutura (Kubernetes, Docker Swarm, etc.).

### Imagem

```
ghcr.io/colaboradorleance/finanalytics:latest
```

Porta exposta: **3000**

### Variáveis de ambiente

| Variável | Obrigatório | Descrição |
|----------|-------------|-----------|
| `DATABASE_URL` | Sim | `postgresql://user:senha@host:5432/banco` |
| `SESSION_SECRET` | Sim | String aleatória longa — `openssl rand -base64 48` |
| `CLIENT_ADMIN_EMAIL` | Sim | Email do primeiro administrador (criado na 1ª inicialização) |
| `CLIENT_ADMIN_PASSWORD` | Sim | Senha inicial do administrador |
| `ANTHROPIC_API_KEY` | Sim | Chave da API Anthropic |
| `FRONTEND_URL` | Sim | URL pública, ex: `https://app.seudominio.com` |
| `PORT` | Não | Porta interna do app (padrão: `3000`) |
| `SMTP_USER` / `SMTP_PASS` | Só para email | Convites e recuperação de senha |
| `LANGFUSE_ENABLED` | Não | `true` para habilitar observabilidade de IA |
| `DOCS_ENABLED` | Não | `true` para habilitar documentação da API em `/api/docs` |

### Passo 1 — Aplicar migrations

Execute **antes** de subir o app pela primeira vez, e a cada atualização que inclua novas migrations:

```bash
docker run --rm \
  -e DATABASE_URL="postgresql://user:senha@host:5432/banco" \
  ghcr.io/colaboradorleance/finanalytics:latest \
  dist/migrate.cjs
```

Saída esperada:
```
[migrate] Conectado ao banco.
[migrate] Aplicando 0000_violet_rhino...
[migrate] ✓ 0000_violet_rhino
...
[migrate] 10 migration(s) aplicada(s) com sucesso.
```

### Passo 2 — Rodar o container

```bash
docker run -d \
  --name finanalytics \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://user:senha@host:5432/banco" \
  -e SESSION_SECRET="string_longa_aqui" \
  -e CLIENT_ADMIN_EMAIL="admin@suaempresa.com" \
  -e CLIENT_ADMIN_PASSWORD="SenhaForte123" \
  -e ANTHROPIC_API_KEY="sk-ant-api03-..." \
  -e FRONTEND_URL="https://app.seudominio.com" \
  ghcr.io/colaboradorleance/finanalytics:latest
```

### Requisito: header X-Forwarded-Proto

O sistema usa cookies com `Secure: true`. Seu proxy reverso **precisa** enviar este header, caso contrário o login não funciona:

```
X-Forwarded-Proto: https
```

Exemplo mínimo com nginx:

```nginx
server {
    listen 443 ssl;
    server_name app.seudominio.com;

    ssl_certificate     /caminho/cert.pem;
    ssl_certificate_key /caminho/key.pem;

    location / {
        proxy_pass         http://localhost:3000;
        proxy_set_header   Host               $host;
        proxy_set_header   X-Real-IP          $remote_addr;
        proxy_set_header   X-Forwarded-For    $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto  https;
        proxy_read_timeout 300s;
    }
}
```

> Alternativas mais simples com HTTPS automático: **Caddy** ou **Traefik**.

---

## Referência completa do .env

```env
# ── Banco de dados (Docker Compose) ──────────────────────────────────────────
DB_USER=finanalytics
DB_PASSWORD=TROQUE_PARA_SENHA_FORTE
DB_NAME=finanalytics

# ── Banco de dados (Modo standalone — substitui as três acima) ───────────────
# DATABASE_URL=postgresql://user:senha@host:5432/banco

# ── Primeiro acesso ───────────────────────────────────────────────────────────
# Criado automaticamente na 1ª inicialização. Troque a senha após entrar.
CLIENT_ADMIN_EMAIL=admin@suaempresa.com
CLIENT_ADMIN_PASSWORD=TroqueSenhaNoFirstLogin

# ── Sessão ────────────────────────────────────────────────────────────────────
# gere com: openssl rand -base64 48
SESSION_SECRET=

# ── Anthropic — obrigatório para as funções de IA ─────────────────────────────
# Obtenha em: https://console.anthropic.com
# O uso é cobrado diretamente na sua conta Anthropic.
ANTHROPIC_API_KEY=sk-ant-api03-...

# ── Rede e ambiente ───────────────────────────────────────────────────────────
PORT=3000
NODE_ENV=production
FRONTEND_URL=https://app.seudominio.com

# ── Email — necessário para convites e recuperação de senha ───────────────────
SMTP_USER=
SMTP_PASS=

# ── Documentação da API (opcional) ────────────────────────────────────────────
# Descomente para habilitar o Swagger UI em /api/docs
# DOCS_ENABLED=true

# ── Observabilidade de IA com Langfuse (opcional) ─────────────────────────────
LANGFUSE_ENABLED=false
# LANGFUSE_PUBLIC_KEY=
# LANGFUSE_SECRET_KEY=
# LANGFUSE_BASE_URL=https://cloud.langfuse.com

# ── API setorial (fornecida pela Finanalytics, se habilitada) ─────────────────
# BEDROCK_NEWS_API_URL=
```

---

## Primeiro acesso

Na primeira inicialização o sistema cria automaticamente o usuário administrador com as credenciais de `CLIENT_ADMIN_EMAIL` e `CLIENT_ADMIN_PASSWORD`.

1. Acesse o sistema no navegador
2. Faça login com o email e senha configurados no `.env`
3. **Troque a senha** nas configurações do perfil
4. Convide outros usuários pelo painel de administração

> Nas inicializações seguintes o sistema detecta que o usuário já existe e não altera a senha — suas mudanças são preservadas.

---

## Gerar API Key para integrações

Para acessar a API programaticamente com `Authorization: Bearer fin_sk_...`:

1. Acesse o sistema e faça login
2. Clique no seu nome → **Minha Conta**
3. Role até **API Keys** → **Gerar**
4. Copie a chave — ela não será exibida novamente

---

## Atualizar para nova versão

### Docker Compose

```bash
# 1. Atualizar este repositório (pode ter novas migrations ou configurações)
git pull

# 2. Baixar a nova imagem
docker compose pull

# 3. Reiniciar o sistema (migrations são aplicadas automaticamente)
docker compose up -d
```

### Modo standalone

```bash
# 1. Baixar a nova imagem
docker pull ghcr.io/colaboradorleance/finanalytics:latest

# 2. Aplicar novas migrations
docker run --rm -e DATABASE_URL="..." \
  ghcr.io/colaboradorleance/finanalytics:latest dist/migrate.cjs

# 3. Reiniciar o container
docker stop finanalytics && docker rm finanalytics
docker run -d ... ghcr.io/colaboradorleance/finanalytics:latest
```

---

## Backup e restauração

### Fazer backup

```bash
docker exec deploy-finanalytics-db-1 \
  pg_dump -U finanalytics finanalytics \
  > backup-$(date +%Y%m%d-%H%M).sql
```

### Restaurar backup

```bash
# Atenção: sobrescreve os dados atuais
docker exec -i deploy-finanalytics-db-1 \
  psql -U finanalytics finanalytics \
  < backup-20260101-1200.sql
```

---

## Comandos úteis (Docker Compose)

```bash
# Logs em tempo real
docker compose logs app -f

# Últimas 100 linhas de log
docker compose logs app --tail 100

# Status de todos os containers
docker compose ps

# Reiniciar somente o app (banco não é afetado)
docker compose restart app

# Parar tudo (dados preservados)
docker compose down

# Parar e apagar tudo incluindo banco — IRREVERSÍVEL
docker compose down -v
```

---

## Solução de problemas

### Login não funciona / sessão some após login

O cookie de sessão não está sendo enviado pelo navegador. Causas:

- **Em produção sem HTTPS:** configure um proxy com SSL e o header `X-Forwarded-Proto: https`
- **`FRONTEND_URL` errada:** deve corresponder exatamente à URL que você acessa no navegador

### Funções de IA retornam erro 401

A `ANTHROPIC_API_KEY` está inválida:

1. Acesse [console.anthropic.com](https://console.anthropic.com) → API Keys
2. Confirme que a chave existe e está ativa
3. Verifique se há créditos disponíveis na conta
4. Corrija no `.env` e reinicie: `docker compose restart app`

> **Causa comum no Windows:** o `.env` editado no Notepad tem `\r` invisível no final das linhas, corrompendo a chave. Use VS Code ou converta com: `sed -i 's/\r//' .env`

### Usuário administrador não foi criado

O sistema só cria o usuário na inicialização se `CLIENT_ADMIN_EMAIL` e `CLIENT_ADMIN_PASSWORD` estiverem definidos no `.env`. Verifique e reinicie:

```bash
docker compose restart app
docker compose logs app | grep -i "client user"
```

Deve aparecer: `[Startup] Client user admin@... created with plan.`

### Migrations falham

```bash
# Ver o erro completo
docker compose logs migrate

# Rodar migrations manualmente
docker compose run --rm migrate
```

### Banco não conecta na primeira vez

```bash
# Ver status do banco
docker compose logs db

# Reiniciar o banco
docker compose restart db
```

Se o banco estiver corrompido de uma tentativa anterior:

```bash
docker compose down -v   # apaga tudo
docker compose up -d     # recria do zero
```

---

## Notas importantes

- **Billing Anthropic:** o uso de IA é cobrado diretamente na sua conta Anthropic. A Finanalytics não intermedia nem controla esses custos.
- **Dados:** ficam no volume Docker `postgres_data`. Sobrevivem a reinicializações. Só são apagados com `docker compose down -v`.
- **Segredos:** trate `SESSION_SECRET`, `ANTHROPIC_API_KEY` e `DB_PASSWORD` como senhas. Nunca commit o `.env`.
