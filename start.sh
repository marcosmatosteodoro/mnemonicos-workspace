#!/usr/bin/env bash
#
# start.sh — cria os symlinks mnemonicos-backend e mnemonicos-frontend neste
# workspace, apontando para as pastas reais dos dois repositórios; garante que o
# Claude Code, o plugin keelson e os MCPs playwright/atlassian estejam
# instalados; confere o GitHub CLI (usado pela skill responder-code-review); e
# atualiza os plugins do Claude Code já instalados.
#
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "${WORKSPACE_DIR}")"

if [ -t 1 ]; then
  COLOR_RED="\033[31m"
  COLOR_GREEN="\033[32m"
  COLOR_RESET="\033[0m"
else
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_RESET=""
fi

ok() { echo -e "${COLOR_GREEN}$*${COLOR_RESET}"; }
err() { echo -e "${COLOR_RED}$*${COLOR_RESET}" >&2; }

# Cria o symlink para um repositório. Se a pasta irmã de mesmo nome existir,
# ela é oferecida como default — é o layout esperado (os três diretórios lado a
# lado); qualquer outro caminho pode ser informado.
create_link() {
  local link_name="$1"
  local link_path="${WORKSPACE_DIR}/${link_name}"
  local default_path="${PARENT_DIR}/${link_name}"

  if [ -L "${link_path}" ]; then
    if [ -d "${link_path}" ]; then
      echo "Symlink '${link_name}' já existe (-> $(readlink "${link_path}")), pulando."
      return 0
    fi
    err "Aviso: symlink '${link_name}' existe mas está quebrado (-> $(readlink "${link_path}")). Recriando."
    rm "${link_path}"
  fi

  if [ -e "${link_path}" ]; then
    err "Erro: '${link_path}' já existe e não é um symlink. Nada foi alterado."
    return 1
  fi

  local prompt="Caminho da pasta ${link_name}"
  if [ -d "${default_path}" ]; then
    prompt="${prompt} [${default_path}]"
  fi

  read -r -p "${prompt}: " target_path

  if [ -z "${target_path}" ] && [ -d "${default_path}" ]; then
    target_path="${default_path}"
  fi

  target_path="${target_path/#\~/$HOME}"

  if [ ! -d "${target_path}" ]; then
    err "Erro: a pasta '${target_path}' não existe ou não é um diretório."
    return 1
  fi

  target_path="$(cd "${target_path}" && pwd)"

  ln -s "${target_path}" "${link_path}"
  ok "OK: ${link_name} -> ${target_path}"
}

create_link "mnemonicos-backend"
create_link "mnemonicos-frontend"

ensure_claude_cli() {
  if command -v claude >/dev/null 2>&1; then
    echo "Claude Code já instalado ($(command -v claude))."
    return 0
  fi

  echo "Claude Code não encontrado, instalando..."
  curl -fsSL https://claude.ai/install.sh | bash

  hash -r
  if ! command -v claude >/dev/null 2>&1; then
    err "Erro: instalação do Claude Code falhou ou não ficou disponível no PATH."
    return 1
  fi

  ok "OK: Claude Code instalado ($(command -v claude))."
}

setup_keelson() {
  echo "Configurando plugin keelson..."

  if claude plugin marketplace list 2>/dev/null | grep -q '^\s*❯\s*keelson\s*$'; then
    echo "Marketplace 'keelson' já configurado."
  else
    claude plugin marketplace add fernandopetry/keelson
  fi

  local plugin_json
  plugin_json="$(claude plugin list --json 2>/dev/null || true)"

  if echo "${plugin_json}" | grep -q '"id": *"keelson@keelson"'; then
    echo "Plugin 'keelson@keelson' já instalado."
  else
    claude plugin install keelson@keelson
    plugin_json="$(claude plugin list --json 2>/dev/null || true)"
  fi

  if echo "${plugin_json}" | grep -A3 '"id": *"keelson@keelson"' | grep -q '"enabled": *true'; then
    echo "Plugin 'keelson@keelson' já ativado."
  else
    claude plugin enable keelson@keelson
  fi

  ok "OK: plugin keelson instalado e ativado."
}

setup_playwright_mcp() {
  if claude mcp get playwright >/dev/null 2>&1; then
    echo "MCP 'playwright' já instalado."
    return 0
  fi

  echo "Instalando MCP playwright..."
  claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
  ok "OK: MCP playwright instalado."
}

setup_atlassian_mcp() {
  if claude mcp get atlassian >/dev/null 2>&1; then
    echo "MCP 'atlassian' já instalado."
    return 0
  fi

  echo "Instalando MCP atlassian..."
  claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp -s user
  ok "OK: MCP atlassian instalado. Rode '/mcp' numa sessão interativa para concluir o login (OAuth) na primeira vez."
}

# O gh não é instalado automaticamente: o pacote oficial exige sudo/apt, e este
# script não roda comando privilegiado sem o usuário pedir.
check_gh_cli() {
  if ! command -v gh >/dev/null 2>&1; then
    err "Aviso: GitHub CLI ('gh') não encontrado — a skill 'responder-code-review' depende dele."
    err "       Instale com: sudo apt install gh    (ou veja https://cli.github.com)"
    err "       Depois autentique: gh auth login"
    return 0
  fi

  if gh auth status >/dev/null 2>&1; then
    ok "OK: GitHub CLI instalado e autenticado."
  else
    err "Aviso: 'gh' instalado mas não autenticado. Rode: gh auth login"
  fi
}

update_all_plugins() {
  if ! command -v jq >/dev/null 2>&1; then
    err "Aviso: comando 'jq' não encontrado, pulando atualização de plugins."
    return 0
  fi

  echo "Atualizando marketplaces..."
  if claude plugin marketplace update; then
    ok "OK: marketplaces atualizados."
  else
    err "Erro ao atualizar marketplaces."
  fi

  echo "Atualizando plugins instalados..."

  local plugin_ids
  plugin_ids="$(claude plugin list --json 2>/dev/null | jq -r '.[].id' | sort -u)"

  if [ -z "${plugin_ids}" ]; then
    echo "Nenhum plugin instalado."
    return 0
  fi

  local failed=0
  local plugin_id
  while IFS= read -r plugin_id; do
    [ -z "${plugin_id}" ] && continue
    echo "Atualizando ${plugin_id}..."
    if claude plugin update "${plugin_id}"; then
      ok "OK: ${plugin_id} atualizado."
    else
      err "Erro ao atualizar ${plugin_id}."
      failed=1
    fi
  done <<< "${plugin_ids}"

  if [ "${failed}" -eq 0 ]; then
    ok "OK: plugins atualizados."
  else
    err "Aviso: alguns plugins falharam ao atualizar (veja mensagens acima)."
  fi
}

if ensure_claude_cli; then
  setup_keelson
  setup_playwright_mcp
  setup_atlassian_mcp
  update_all_plugins
else
  err "Aviso: pulando setup do keelson, dos MCPs e da atualização de plugins."
fi

check_gh_cli

if [ ! -f "${WORKSPACE_DIR}/keelson.local.json" ]; then
  err "Aviso: 'keelson.local.json' não existe. Crie esse arquivo (veja 'keelson.local.example.json' como modelo)."
fi

ok "Concluído."
