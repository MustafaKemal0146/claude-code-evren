#!/usr/bin/env bash
# claude-code-evren: geri alma
# - kabuk dosyasındaki işaretli bloğu siler
# - ~/.config/evren/evren.sh dosyasını siler
# - anahtar dosyasını sadece --purge ile (veya sorarak) siler
# - ~/.claude/settings.json içinde EVREN'den kalan model/env satırlarını temizler
set -euo pipefail

EVREN_DIR="$HOME/.config/evren"
RC=""
PURGE=0

usage() {
  cat <<'EOF'
Kullanım: bash scripts/uninstall.sh [seçenekler]

  --rc DOSYA   Hangi kabuk dosyasından silinsin (varsayılan: zsh ise ~/.zshrc, değilse ~/.bashrc)
  --purge      Anahtar dosyasını (~/.config/evren/env) da sil, sormadan
  -h, --help   Bu yardım
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --rc) RC="${2:?--rc için dosya yolu ver}"; shift 2 ;;
    --purge) PURGE=1; shift ;;
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

# 1) Kabuk dosyasındaki blok
if [ -f "$RC" ] && grep -qx '# >>> evren >>>' "$RC"; then
  cp "$RC" "$RC.evren-uninstall.bak"
  TMP="$(mktemp)"
  sed '/^# >>> evren >>>$/,/^# <<< evren <<<$/d' "$RC" \
    | awk '{a[NR]=$0} END{n=NR; while(n>0 && a[n]=="") n--; for(i=1;i<=n;i++) print a[i]}' > "$TMP"
  cat "$TMP" > "$RC"
  rm -f "$TMP"
  echo "✔ Blok silindi: $RC (yedek: $RC.evren-uninstall.bak)"
else
  echo "• $RC içinde evren bloğu yok, atlandı"
fi

# 2) Fonksiyon dosyası
if [ -f "$EVREN_DIR/evren.sh" ]; then
  rm -f "$EVREN_DIR/evren.sh"
  echo "✔ Silindi: $EVREN_DIR/evren.sh"
fi

# 3) Anahtar dosyası
if [ -f "$EVREN_DIR/env" ]; then
  DEL=0
  if [ "$PURGE" -eq 1 ]; then
    DEL=1
  elif [ -t 0 ]; then
    printf 'Anahtar dosyası da silinsin mi (%s)? [e/H] ' "$EVREN_DIR/env"
    read -r ans
    case "$ans" in e|E|evet|Evet) DEL=1 ;; esac
  fi
  if [ "$DEL" -eq 1 ]; then
    rm -f "$EVREN_DIR/env"
    echo "✔ Anahtar dosyası silindi"
  else
    echo "• Anahtar dosyası duruyor: $EVREN_DIR/env (silmek için: --purge)"
  fi
fi
rmdir "$EVREN_DIR" 2>/dev/null || true

# 4) Claude Code settings.json içinde EVREN'den kalanlar
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$SETTINGS" <<'PY'
import json, shutil, sys

path = sys.argv[1]
EVREN_MODELS = {"deepseek-v4.1-flash", "deepseek-v4-flash", "glm-5.3",
                "mimo-v2.6-pro", "qwen3.8-flash-next"}
OUR_ENV = {"ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_MODEL",
           "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL",
           "ANTHROPIC_DEFAULT_HAIKU_MODEL", "CLAUDE_CODE_SUBAGENT_MODEL",
           "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"}
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"• settings.json okunamadı, atlandı ({e})")
    sys.exit(0)

removed = []
if isinstance(data, dict):
    if data.get("model") in EVREN_MODELS:
        removed.append(f'model="{data.pop("model")}"')
    env = data.get("env")
    if isinstance(env, dict) and "evren-llmapi.ssyz.org.tr" in str(env.get("ANTHROPIC_BASE_URL", "")):
        for k in sorted(OUR_ENV & set(env)):
            env.pop(k)
            removed.append(f"env.{k}")
        if not env:
            data.pop("env")

if removed:
    shutil.copy(path, path + ".evren.bak")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("✔ settings.json temizlendi: " + ", ".join(removed))
    print(f"  Yedek: {path}.evren.bak")
else:
    print("• settings.json içinde EVREN'den kalan bir şey yok")
PY
  else
    echo "! python3 yok, $SETTINGS elle kontrol et: \"model\" satırı glm-5.3 / deepseek-v4.1-flash gibi bir EVREN modeli ise sil" >&2
  fi
fi

cat <<'EOF'

Bitti. Açık terminalde komutu hemen kaldırmak için:
  unset -f evren

Dokunmadıklarım:
  - ANTHROPIC_API_KEY (normal Claude hesabın, hiç değiştirilmedi)
  - Proje içi .claude/settings.local.json dosyaları (varsa kendin kontrol et)

Anahtarı artık kullanmayacaksan EVREN panelinde API Anahtarları sayfasından sil.
EOF
