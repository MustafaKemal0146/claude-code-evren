# EVREN x Claude Code: Windows PowerShell `evren` komutu
# DURUM: Doğrulanmadı (yazan makinede Windows yoktu). Denersen README'ye sonucu yaz.
#
# Kurulum:
#   1) Anahtarı kalıcı yaz (yeni terminalde geçerli olur):
#        [Environment]::SetEnvironmentVariable("EVREN_API_KEY", "evren_llm_...", "User")
#   2) Bu dosyayı bir yere kopyala, örn. $HOME\.config\evren\evren.ps1
#   3) $PROFILE dosyasına şu satırı ekle:
#        . "$HOME\.config\evren\evren.ps1"
#
# Kullanım:
#   evren                        # menü açılır
#   evren deepseek-v4.1-flash    # menüsüz
#   evren glm-5.3 -p "selam"     # model + Claude Code argümanları

function evren {
    param(
        [string]$Model,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Rest
    )

    $models = @("deepseek-v4.1-flash", "glm-5.3", "mimo-v2.6-pro", "qwen3.8-flash-next")

    if (-not $Model) {
        Write-Host "Model seç:"
        for ($i = 0; $i -lt $models.Count; $i++) {
            Write-Host ("{0}) {1}" -f ($i + 1), $models[$i])
        }
        $n = Read-Host "Numara"
        if ($n -notmatch '^[1-4]$') {
            Write-Error "Geçersiz seçim: $n"
            return
        }
        $Model = $models[[int]$n - 1]
    }

    if (-not $env:EVREN_API_KEY) {
        Write-Error "EVREN_API_KEY tanımlı değil. [Environment]::SetEnvironmentVariable('EVREN_API_KEY','evren_llm_...','User') ile yaz, yeni terminal aç."
        return
    }

    $names = @(
        "ANTHROPIC_API_KEY", "ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN",
        "ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_OPUS_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL", "CLAUDE_CODE_SUBAGENT_MODEL",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
    )

    # Mevcut değerleri sakla, Claude kapanınca geri yükle (geri alma garantisi)
    $saved = @{}
    foreach ($k in $names) {
        $saved[$k] = [Environment]::GetEnvironmentVariable($k, "Process")
    }

    try {
        [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "Process")
        $env:ANTHROPIC_BASE_URL = "https://evren-llmapi.ssyz.org.tr"
        $env:ANTHROPIC_AUTH_TOKEN = $env:EVREN_API_KEY
        $env:ANTHROPIC_MODEL = $Model
        $env:ANTHROPIC_DEFAULT_OPUS_MODEL = $Model
        $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $Model
        $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "qwen3.8-flash-next"
        $env:CLAUDE_CODE_SUBAGENT_MODEL = $Model
        $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
        Write-Host ">> Model: $Model"
        & claude @Rest
    }
    finally {
        foreach ($k in $names) {
            [Environment]::SetEnvironmentVariable($k, $saved[$k], "Process")
        }
    }
}
