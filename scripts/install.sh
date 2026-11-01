#!/usr/bin/env bash
# claude-code-evren: kurulum
# - ~/.config/evren/evren.sh   (evren komutu)
# - ~/.config/evren/env        (EVREN_API_KEY, izin 600)
# - ~/.bashrc veya ~/.zshrc    (işaretli tek blok, tekrar çalıştırmak güvenli)
set -euo pipefail

EVREN_DIR="$HOME/.config/evren"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC=""
NO_KEY=0

usage() {
  cat <<'EOF'
Kullanım: bash scripts/install.sh [seçenekler]

  --rc DOSYA   Hangi kabuk dosyasına yazılsın (varsayılan: zsh ise ~/.zshrc, değilse ~/.bashrc)
  --no-key     Anahtar sorma, anahtar dosyasını oluşturma
  -h, --help   Bu yardım

Anahtarı soru sormadan vermek için:
  EVREN_API_KEY="evren_llm_..." bash scripts/install.sh
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --rc) RC="${2:?--rc için dosya yolu ver}"; shift 2 ;;
    --no-key) NO_KEY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Bilinmeyen seçenek: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$RC" ]; then
  case "$(basename "${SHELL:-bash}")" in
    zsh) RC="$HOME/.zshrc" ;;
    *)   RC="$HOME/.bashrc" ;;
  esac
fi

# 1) Fonksiyon dosyası
mkdir -p "$EVREN_DIR"
chmod 700 "$EVREN_DIR"
install -m 644 "$SRC/evren.sh" "$EVREN_DIR/evren.sh"
echo "✔ evren komutu kopyalandı: $EVREN_DIR/evren.sh"

# 2) Anahtar dosyası
ENV_FILE="$EVREN_DIR/env"
if [ -f "$ENV_FILE" ]; then
  echo "• Anahtar dosyası zaten var, dokunulmadı: $ENV_FILE"
elif [ "$NO_KEY" -eq 1 ]; then
  echo "• --no-key: anahtar dosyası oluşturulmadı"
else
  KEY="${EVREN_API_KEY:-}"
  if [ -z "$KEY" ] && [ -t 0 ]; then
    printf 'EVREN API anahtarın (evren_llm_..., yazarken görünmez): '
    read -rs KEY
    echo
  fi
  if [ -z "$KEY" ]; then
    echo "• Anahtar verilmedi, atlandı. Sonra elle yaz: nano $ENV_FILE"
  else
    case "$KEY" in
      evren_llm_*) ;;
      *) echo "! Uyarı: anahtar evren_llm_ ile başlamıyor, yine de yazıyorum" >&2 ;;
    esac
    ( umask 077; printf 'export EVREN_API_KEY=%q\n' "$KEY" > "$ENV_FILE" )
    chmod 600 "$ENV_FILE"
    echo "✔ Anahtar yazıldı (izin 600): $ENV_FILE"
  fi
fi

# 3) Kabuk dosyasına işaretli blok (varsa değiştirir, çoğaltmaz)
touch "$RC"
[ -f "$RC.evren.bak" ] || cp "$RC" "$RC.evren.bak"
TMP="$(mktemp)"
sed '/^# >>> evren >>>$/,/^# <<< evren <<<$/d' "$RC" \
  | awk '{a[NR]=$0} END{n=NR; while(n>0 && a[n]=="") n--; for(i=1;i<=n;i++) print a[i]}' > "$TMP"
{
  cat "$TMP"
  printf '\n# >>> evren >>>\n'
  printf '%s\n' '[ -f "$HOME/.config/evren/evren.sh" ] && . "$HOME/.config/evren/evren.sh"'
  printf '# <<< evren <<<\n'
} > "$RC"
rm -f "$TMP"
echo "✔ Blok eklendi: $RC (yedek: $RC.evren.bak)"

command -v claude >/dev/null 2>&1 || echo "! 'claude' komutu bulunamadı. Önce Claude Code'u kur: https://code.claude.com" >&2
if grep -q 'ANTHROPIC_API_KEY' "$RC" 2>/dev/null; then
  echo "• $RC içinde ANTHROPIC_API_KEY var. Sorun değil: evren onu sadece kendi oturumunda siler, dosyana dokunmam."
fi

cat <<EOF

Sıradaki adımlar:
  1) source $RC
  2) Kullanım şartlarını onayla (hesap başına bir kez, README'deki 'Şartlar' bölümü)
  3) evren
EOF
