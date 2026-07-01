# FinAnalytics — Guia de Deploy

Este repositório contém tudo que é necessário para subir o sistema FinAnalytics em qualquer servidor.
Não há código-fonte aqui — apenas configuração de infraestrutura.

---

## Escolha sua forma de deploy

| Cenário | Use |
|---------|-----|
| Servidor simples / primeiro uso | [Docker Compose](#instalação-com-docker-compose) — banco incluso, tudo configurado |
| Kubernetes / infraestrutura própria / banco externo | [Somente a imagem](#usando-somente-a-imagem) — integre na sua stack |

---

## Usando somente a imagem

Para quem já tem banco de dados, proxy reverso e quer integrar o container na própria infraestrutura.

### Imagem

```
ghcr.io/colaboradorleance/finanalytics:latest
```

> Para autenticar no registro: `echo SEU_TOKEN | docker login ghcr.io -u ColaboradorLeance --password-stdin`

### Porta exposta

O container expõe a porta `3000`.

### Variáveis de ambiente obrigatórias

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | `postgresql://user:senha@host:5432/dbname` |
| `SESSION_SECRET` | String aleatória longa (mín. 48 chars) — `openssl rand -base64 48` |
| `CLIENT_ADMIN_EMAIL` | Email do primeiro usuário admin (criado na 1ª inicialização) |
| `CLIENT_ADMIN_PASSWORD` | Senha inicial do primeiro usuário admin |
| `ANTHROPIC_API_KEY` | Chave da API Anthropic (console.anthropic.com) |
| `FRONTEND_URL` | URL pública do sistema, ex: `https://app.seudominio.com` |

Variáveis opcionais: `PORT` (padrão `3000`), `SMTP_USER`, `SMTP_PASS`, `LANGFUSE_ENABLED`, `BEDROCK_NEWS_API_URL`.

### Passo 1 — Aplicar migrations

Execute **antes** de subir o container pela primeira vez (e a cada atualização com novas migrations):

```bash
docker run --rm \
  -e DATABASE_URL="postgresql://user:senha@host:5432/dbname" \
  ghcr.io/colaboradorleance/finanalytics:latest \
  dist/migrate.cjs
```

### Passo 2 — Rodar o container

```bash
docker run -d \
  --name finanalytics \
  --restart unless-stopped \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://user:senha@host:5432/dbname" \
  -e SESSION_SECRET="sua_session_secret_aqui" \
  -e CLIENT_ADMIN_EMAIL="admin@suaempresa.com" \
  -e CLIENT_ADMIN_PASSWORD="SuaSenhaForte123" \
  -e ANTHROPIC_API_KEY="sk-ant-api03-..." \
  -e FRONTEND_URL="https://app.seudominio.com" \
  ghcr.io/colaboradorleance/finanalytics:latest
```

### Requisito importante — header X-Forwarded-Proto

O sistema usa cookies com `Secure: true`. Seu proxy reverso **precisa** enviar o header:

```
X-Forwarded-Proto: https
```

Sem esse header, o login não funciona. Exemplo para nginx:

```nginx
location / {
    proxy_pass         http://localhost:3000;
    proxy_set_header   Host              $host;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto https;
    proxy_read_timeout 300s;
}
```

### Verificar

```bash
curl http://localhost:3000/api/health
# {"status":"ok"}
```

---

## O que está incluído

| Arquivo/Pasta | Função |
|---------------|--------|
| `docker-compose.yml` | Orquestra banco, migrations e aplicação |
| `nginx/default.conf` | Proxy reverso interno (necessário para login funcionar) |
| `migrations/` | Scripts SQL de criação e atualização do banco |
| `drizzle.config.js` | Configuração do runner de migrations |
| `.env.example` | Modelo das variáveis de ambiente |

---

## Pré-requisitos

| Requisito | Versão mínima | Como verificar |
|-----------|---------------|----------------|
| Docker | 24.0 | `docker --version` |
| Docker Compose | 2.20 | `docker compose version` |
| Acesso à internet | — | Para baixar a imagem e conectar à Anthropic |

---

## Instalação passo a passo

### 1. Clonar este repositório

```bash
git clone https://github.com/ColaboradorLeance/deploy-finanalytics.git
cd deploy-finanalytics
```

### 2. Criar o arquivo de configuração

```bash
cp .env.example .env
```

Abra o arquivo `.env` e preencha os campos. Veja a seção **Referência completa do .env** abaixo.


### 3. Subir o sistema

```bash
docker compose up -d
```

O Docker vai executar automaticamente, nesta ordem:

1. Iniciar o banco de dados PostgreSQL
2. Aguardar o banco estar pronto
3. Aplicar todas as migrations de banco
4. Iniciar a aplicação
5. Iniciar o proxy nginx

### 4. Verificar se está funcionando

```bash
curl http://localhost:3000/api/health
```

Resposta esperada:
```json
{"status":"ok"}
```

Acesse `http://localhost:3000` no navegador — a tela de login deve aparecer.

---

## Referência completa do .env

Copie o `.env.example` e preencha campo a campo:

```env
# Banco de dados
DB_USER=finanalytics
DB_PASSWORD=TROQUE_PARA_UMA_SENHA_FORTE
DB_NAME=finanalytics
```

```env
# Sessão — gere com: openssl rand -base64 48
SESSION_SECRET=
```

```env
# Primeiro acesso — usuário administrador do cliente
# Criado automaticamente na primeira inicialização.
# Após entrar, troque a senha nas configurações do perfil.
CLIENT_ADMIN_EMAIL=admin@suaempresa.com
CLIENT_ADMIN_PASSWORD=troque_esta_senha_no_primeiro_acesso
```

```env
# Chave da API Anthropic — obtenha em console.anthropic.com
# O uso de IA é cobrado diretamente na sua conta Anthropic
ANTHROPIC_API_KEY=sk-ant-...
```

```env
# Porta exposta pelo sistema no servidor
PORT=3000
NODE_ENV=production

# Documentação da API — descomente para habilitar /api/docs
# DOCS_ENABLED=true
```

```env
# URL pública do sistema (necessária para links de email e CORS)
FRONTEND_URL=https://app.seudominio.com
```

```env
# Email — necessário para convites e recuperação de senha
SMTP_USER=
SMTP_PASS=
```

```env
# Observabilidade de IA — opcional
LANGFUSE_ENABLED=false
# LANGFUSE_PUBLIC_KEY=
# LANGFUSE_SECRET_KEY=
# LANGFUSE_BASE_URL=https://cloud.langfuse.com
```

### Campos obrigatórios para o sistema funcionar

| Campo | Obrigatório | Motivo |
|-------|-------------|--------|
| `DB_PASSWORD` | Sim | Sem senha, o banco não sobe |
| `SESSION_SECRET` | Sim | Sem ele, sessões de login não funcionam |
| `CLIENT_ADMIN_EMAIL` | Sim | Email do primeiro usuário administrador |
| `CLIENT_ADMIN_PASSWORD` | Sim | Senha inicial do primeiro usuário |
| `ANTHROPIC_API_KEY` | Sim | Sem ela, todas as funções de IA falham |
| `FRONTEND_URL` | Sim | Necessário para CORS e links de email |
| `SMTP_USER` / `SMTP_PASS` | Só se usar email | Convites e recuperação de senha |

> **Atenção:** Nunca commit o arquivo `.env`. Ele já está no `.gitignore` e contém segredos.

---

## Gerar API key para integrações

Para acessar a API programaticamente via `Authorization: Bearer fin_sk_...`:

1. Acesse `http://localhost:3000` e faça login
2. Clique no seu nome/perfil → **Minha Conta**
3. Role até a seção **API Keys**
4. Digite um nome para a chave e clique em **Gerar**
5. **Copie a chave imediatamente** — ela não será exibida novamente

---

## Primeiro acesso

Na primeira inicialização, o sistema cria automaticamente um usuário com as credenciais definidas em `CLIENT_ADMIN_EMAIL` e `CLIENT_ADMIN_PASSWORD`.

1. Acesse `http://localhost:3000` (ou o domínio configurado)
2. Entre com o email e senha definidos no `.env`
3. **Troque a senha imediatamente** nas configurações do perfil
4. A partir daí, você pode convidar outros usuários pelo painel de administração

> Nas reinicializações seguintes o sistema detecta que o usuário já existe e não altera a senha — suas mudanças são preservadas.

---

## Por que o login exige HTTPS em produção

O sistema usa cookies de sessão com `Secure: true`. Isso significa que o navegador só envia o cookie via HTTPS — em HTTP puro, o login parece funcionar mas a sessão some na próxima requisição.

**Em ambiente local** (mesma máquina, `localhost`), isso já está resolvido: o nginx incluído no `docker-compose.yml` injeta o header `X-Forwarded-Proto: https`, enganando o sistema para funcionar normalmente.

**Em produção** (servidor real com domínio), você precisa de um proxy reverso com certificado SSL na frente. Exemplo com nginx externo:

```nginx
server {
    listen 443 ssl;
    server_name app.seudominio.com;

    ssl_certificate     /caminho/para/cert.pem;
    ssl_certificate_key /caminho/para/key.pem;

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

Alternativas mais simples: **Caddy** (gera certificado automaticamente) ou **Traefik**.

---

## Atualizar para uma nova versão

Quando a Finanalytics lançar uma nova versão:

```bash
# 1. Atualizar este repositório (pode ter novas migrations ou configs)
git pull

# 2. Baixar a nova imagem
docker compose pull app

# 3. Reiniciar somente a aplicação (banco não é afetado)
docker compose up -d app
```

> Se o `git pull` trouxer novos arquivos em `migrations/`, as migrations são aplicadas automaticamente quando o compose sobe.

---

## Backup e restauração

### Fazer backup do banco

```bash
docker exec deploy-finanalytics-db-1 \
  pg_dump -U finanalytics finanalytics \
  > backup-$(date +%Y%m%d).sql
```

### Restaurar backup

```bash
# Atenção: isso sobrescreve os dados atuais
docker exec -i deploy-finanalytics-db-1 \
  psql -U finanalytics finanalytics \
  < backup-20260101.sql
```

---

## Comandos úteis do dia a dia

```bash
# Ver logs em tempo real
docker compose logs app -f

# Ver somente os últimos 100 linhas de log
docker compose logs app --tail 100

# Ver status de todos os containers
docker compose ps

# Reiniciar somente a aplicação (sem derrubar o banco)
docker compose restart app

# Parar tudo sem apagar dados
docker compose down

# Parar e apagar TUDO incluindo banco — CUIDADO, dados são perdidos
docker compose down -v
```

---

## Solução de problemas comuns

### Login não funciona / sessão some

O navegador não está enviando o cookie de sessão. Causas:

1. **Em produção sem HTTPS:** configure um proxy com SSL (ver seção acima)
2. **Cookie bloqueado por navegador:** verifique se `FRONTEND_URL` corresponde exatamente à URL que você acessa

### Funções de IA retornam erro 401

A `ANTHROPIC_API_KEY` está inválida ou com problema:

1. Acesse [console.anthropic.com](https://console.anthropic.com) → API Keys
2. Confirme que a chave existe e está ativa
3. Verifique se a conta tem créditos disponíveis
4. Edite o `.env`, corrija a chave e reinicie: `docker compose up -d app`

> **Atenção:** Se o `.env` foi editado no Windows (Notepad, por exemplo), pode ter caracteres invisíveis `\r` no final das linhas. Isso corrompem a chave. Use um editor como VS Code, ou converta com: `sed -i 's/\r//' .env`

### Banco não conecta na primeira vez

```bash
# Ver logs do banco
docker compose logs db

# Forçar reinício do banco
docker compose restart db
```

Se o banco estiver com dados corrompidos de uma tentativa anterior:

```bash
docker compose down -v   # apaga tudo
docker compose up -d     # recria do zero
```

### Migrations falham

```bash
# Ver logs das migrations
docker compose logs migrate

# Rodar migrations manualmente
docker compose run --rm migrate
```

---

## Notas importantes

- **Billing Anthropic:** o uso de IA (análises, extração, notícias) é cobrado diretamente na sua conta Anthropic. A Finanalytics não intermedia nem controla esse custo.
- **Dados do banco:** ficam no volume Docker `postgres_data`. Enquanto você não rodar `docker compose down -v`, os dados são preservados entre reinicializações.
- **Segredos:** nunca compartilhe o arquivo `.env`. Trate `SESSION_SECRET` e `ANTHROPIC_API_KEY` como senhas.
