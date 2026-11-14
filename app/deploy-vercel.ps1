$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar a versao web. Publicacao interrompida.' }
    Copy-Item -LiteralPath 'web/vercel.json' -Destination 'build/web/vercel.json' -Force
    Push-Location 'build/web'
    try {
        & npx --yes vercel --prod
        if ($LASTEXITCODE -ne 0) { throw 'A Vercel nao concluiu a publicacao.' }
    } finally {
        Pop-Location
    }
} finally {
    Pop-Location
}
