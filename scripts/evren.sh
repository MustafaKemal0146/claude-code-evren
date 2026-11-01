# EVREN x Claude Code: `evren` komutu
# Bu dosya install.sh tarafından ~/.config/evren/evren.sh olarak kopyalanır
# ve ~/.bashrc (veya ~/.zshrc) içinden source edilir.
#
# Kullanım:
#   evren                        # menü açılır, model seç
#   evren deepseek-v4.1-flash    # menüsüz, direkt aç
#   evren glm-5.3 -p "selam"     # model + Claude Code argümanları

evren() {
  local models=("deepseek-v4.1-flash" "glm-5.3" "mimo-v2.6-pro" "qwen3.8-flash-next")
  local m="$1"
  if [ -n "$m" ]; then
    shift
  else
    echo "Model seç:"
    PS3="Numara: "
    select m in "${models[@]}"; do [ -n "$m" ] && break; done
  fi
  [ -n "$m" ] || return 1
  (
    . "$HOME/.config/evren/env" 2>/dev/null || { echo "Anahtar dosyası yok: ~/.config/evren/env" >&2; exit 1; }
    [ -n "$EVREN_API_KEY" ] || { echo "EVREN_API_KEY boş" >&2; exit 1; }
    unset ANTHROPIC_API_KEY
    export ANTHROPIC_BASE_URL="https://evren-llmapi.ssyz.org.tr"
    export ANTHROPIC_AUTH_TOKEN="$EVREN_API_KEY"
    export ANTHROPIC_MODEL="$m"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$m"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$m"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="qwen3.8-flash-next"
    export CLAUDE_CODE_SUBAGENT_MODEL="$m"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    echo ">> Model: $m"
    claude "$@"
  )
}
