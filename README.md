# FinAnalytics — Deploy

Instruções para rodar o sistema FinAnalytics usando a imagem Docker oficial.

---

## Imagem

```
ghcr.io/colaboradorleance/finanalytics:latest
```

Porta exposta: **3000**

---

## Pré-requisitos

- Docker instalado (`docker --version`)
- Banco de dados **PostgreSQL 14+** acessível pelo container
- Proxy reverso com HTTPS na frente do sistema (nginx, Traefik, Caddy…)
- Token de acesso à imagem — solicite à Finanalytics

> **Windows (PowerShell):** os comandos abaixo usam `\` para quebrar linhas (sintaxe Linux/bash). No PowerShell substitua `\` por `` ` `` (backtick), ou escreva o comando inteiro em uma linha.

---

## Instalação

### 1. Autenticar no registro de imagens

```bash
echo SEU_TOKEN | docker login ghcr.io -u ColaboradorLeance --password-stdin
```

Só precisa fazer isso uma vez por máquina.

### 2. Criar o arquivo de variáveis de ambiente

Baixe o modelo e preencha:

```bash
curl -o .env https://raw.githubusercontent.com/ColaboradorLeance/deploy-finanalytics/main/.env.example
```

Ou crie manualmente com base na seção [Variáveis de ambiente](#variáveis-de-ambiente) abaixo.

### 3. Aplicar migrations do banco

Execute **antes** de subir o app pela primeira vez. Repita a cada atualização com novas migrations:

```bash
docker run --rm --env-file .env \
  ghcr.io/colaboradorleance/finanalytics:latest \
  dist/migrate.cjs
```

Saída esperada (banco novo):
```
[migrate] Conectado ao banco.
[migrate] Aplicando 0000_violet_rhino...
[migrate] ✓ 0000_violet_rhino
...
[migrate] N migration(s) aplicada(s) com sucesso.
```

Se executar novamente sem novas migrations:
```
[migrate] Banco já está atualizado.
```

### 4. Subir o container

```bash
docker run -d \
  --name finanalytics \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  ghcr.io/colaboradorleance/finanalytics:latest
```

### 5. Verificar

```bash
curl http://localhost:3000/api/health
# {"status":"ok"}
```

---

## Variáveis de ambiente

Todas as variáveis ficam no arquivo `.env`. Copie o `.env.example` como ponto de partida.

### Obrigatórias

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | String de conexão PostgreSQL: `postgresql://user:senha@host:5432/banco` |
| `SESSION_SECRET` | Chave de sessão — gere com `openssl rand -base64 48` |
| `CLIENT_ADMIN_EMAIL` | Email do primeiro administrador (criado na 1ª inicialização) |
| `CLIENT_ADMIN_PASSWORD` | Senha inicial do administrador |
| `ANTHROPIC_API_KEY` | Chave da API Anthropic — obtenha em [console.anthropic.com](https://console.anthropic.com) |
| `FRONTEND_URL` | URL pública do sistema, ex: `https://app.seudominio.com` |

### Opcionais

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `PORT` | `3000` | Porta interna do app |
| `NODE_ENV` | `production` | Ambiente de execução |
| `SMTP_USER` | — | Usuário SMTP para envio de emails |
| `SMTP_PASS` | — | Senha SMTP |
| `DOCS_ENABLED` | `false` | `true` habilita Swagger UI em `/api/docs` |
| `LANGFUSE_ENABLED` | `false` | `true` habilita observabilidade de IA |
| `LANGFUSE_PUBLIC_KEY` | — | Chave pública do Langfuse |
| `LANGFUSE_SECRET_KEY` | — | Chave secreta do Langfuse |
| `LANGFUSE_BASE_URL` | — | URL do servidor Langfuse |
| `BEDROCK_NEWS_API_URL` | — | API setorial (fornecida pela Finanalytics) |

---

## Proxy reverso — requisito obrigatório

O sistema usa cookies com `Secure: true`. **Sem HTTPS e sem o header `X-Forwarded-Proto: https`, o login não funciona.**

Seu proxy reverso precisa:
1. Terminar TLS (HTTPS)
2. Repassar o header `X-Forwarded-Proto: https` ao container

### Exemplo com nginx

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

### Alternativas simples

- **Caddy** — gera certificado SSL automaticamente, configuração mínima
- **Traefik** — ideal para Docker/Kubernetes, SSL automático via Let's Encrypt

---

## Primeiro acesso

Na primeira inicialização o sistema cria automaticamente o usuário administrador com as credenciais definidas em `CLIENT_ADMIN_EMAIL` e `CLIENT_ADMIN_PASSWORD`.

1. Acesse o sistema no navegador
2. Faça login com email e senha do `.env`
3. **Troque a senha** nas configurações do perfil
4. Convide outros usuários pelo painel de administração

> Nas inicializações seguintes o sistema detecta que o usuário já existe e não altera a senha.

---

## Gerar API Key para integrações

Para acessar a API com `Authorization: Bearer fin_sk_...`:

1. Faça login no sistema
2. Clique no seu nome → **Minha Conta**
3. Seção **API Keys** → **Gerar**
4. Copie a chave — ela não será exibida novamente

---

## Atualizar para nova versão

```bash
# 1. Baixar nova imagem
docker pull ghcr.io/colaboradorleance/finanalytics:latest

# 2. Aplicar novas migrations (se houver)
docker run --rm --env-file .env \
  ghcr.io/colaboradorleance/finanalytics:latest dist/migrate.cjs

# 3. Reiniciar o container
docker stop finanalytics
docker rm finanalytics
docker run -d --name finanalytics --restart unless-stopped -p 3000:3000 \
  --env-file .env ghcr.io/colaboradorleance/finanalytics:latest
```

---

## Comandos úteis

```bash
# Logs em tempo real
docker logs finanalytics -f

# Últimas 100 linhas de log
docker logs finanalytics --tail 100

# Status do container
docker ps -f name=finanalytics

# Reiniciar
docker restart finanalytics

# Parar
docker stop finanalytics

# Remover container (não apaga dados do banco)
docker rm finanalytics
```

---

## Solução de problemas

### Login não funciona / sessão some

O browser está rejeitando o cookie. Causas:

- Proxy reverso não envia `X-Forwarded-Proto: https` → adicione o header
- Acessando via HTTP puro → configure SSL no proxy
- `FRONTEND_URL` diferente da URL do browser → corrija para a URL exata que você acessa

### Funções de IA retornam erro 401

A `ANTHROPIC_API_KEY` está inválida:

1. Acesse [console.anthropic.com](https://console.anthropic.com) → API Keys
2. Confirme que a chave existe e está ativa
3. Verifique se a conta tem créditos disponíveis
4. Corrija no `.env` e reinicie: `docker restart finanalytics`

> **Windows:** se o `.env` foi editado no Notepad, pode ter `\r` invisível corrompendo a chave. Use VS Code ou converta: `sed -i 's/\r//' .env`

### Usuário administrador não foi criado

Verifique os logs na inicialização:

```bash
docker logs finanalytics | grep -i "client user"
```

Se não aparecer nada, `CLIENT_ADMIN_EMAIL` ou `CLIENT_ADMIN_PASSWORD` não estão definidos no `.env`. Corrija e reinicie.

### Migrations falham

```bash
# Ver erro completo
docker run --rm --env-file .env \
  ghcr.io/colaboradorleance/finanalytics:latest dist/migrate.cjs
```

> O runner detecta automaticamente bancos que foram configurados anteriormente pelo drizzle-kit e não tenta re-aplicar migrations já existentes.

---

## Notas

- **Billing Anthropic:** o uso de IA é cobrado diretamente na sua conta Anthropic. A Finanalytics não intermedia esses custos.
- **Dados:** ficam no banco PostgreSQL que você gerencia. O container é stateless.
- **Segredos:** nunca compartilhe o `.env`. Trate `SESSION_SECRET`, `ANTHROPIC_API_KEY` e a senha do banco como senhas.
