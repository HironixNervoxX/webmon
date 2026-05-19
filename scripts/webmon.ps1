# WebMon - Script PowerShell équivalent au Makefile
# Usage : .\scripts\webmon.ps1 <commande>

param(
    [Parameter(Position=0)]
    [ValidateSet("help", "start", "stop", "restart", "logs", "ps", "status",
                 "health", "clean", "build", "backup", "restore", "chaos", "stress")]
    [string]$Action = "help"
)

function Show-Help {
    Write-Host ""
    Write-Host "WebMon - Commandes disponibles :" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\scripts\webmon.ps1 start    " -NoNewline; Write-Host "Démarre toute la stack"
    Write-Host "  .\scripts\webmon.ps1 stop     " -NoNewline; Write-Host "Arrête la stack"
    Write-Host "  .\scripts\webmon.ps1 restart  " -NoNewline; Write-Host "Redémarre"
    Write-Host "  .\scripts\webmon.ps1 logs     " -NoNewline; Write-Host "Logs en temps réel"
    Write-Host "  .\scripts\webmon.ps1 ps       " -NoNewline; Write-Host "Liste les conteneurs"
    Write-Host "  .\scripts\webmon.ps1 status   " -NoNewline; Write-Host "Statut détaillé"
    Write-Host "  .\scripts\webmon.ps1 health   " -NoNewline; Write-Host "Healthcheck endpoints"
    Write-Host "  .\scripts\webmon.ps1 clean    " -NoNewline; Write-Host "Stop + supprime volumes"
    Write-Host "  .\scripts\webmon.ps1 build    " -NoNewline; Write-Host "Rebuild les images"
    Write-Host "  .\scripts\webmon.ps1 backup   " -NoNewline; Write-Host "Sauvegarde Postgres"
    Write-Host "  .\scripts\webmon.ps1 restore  " -NoNewline; Write-Host "Restaure dernière sauvegarde"
    Write-Host "  .\scripts\webmon.ps1 chaos    " -NoNewline; Write-Host "Tue un conteneur au hasard"
    Write-Host "  .\scripts\webmon.ps1 stress   " -NoNewline; Write-Host "30s de charge CPU"
    Write-Host ""
}

function Show-Banner {
    Write-Host ""
    Write-Host "🌐 App         : http://localhost" -ForegroundColor Green
    Write-Host "📊 Grafana     : http://localhost:3000 (admin/admin)" -ForegroundColor Green
    Write-Host "📈 Prometheus  : http://localhost:9090" -ForegroundColor Green
    Write-Host "📦 cAdvisor    : http://localhost:8080" -ForegroundColor Green
    Write-Host ""
}

function Test-Endpoint($name, $url) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        Write-Host ("  {0,-18} : OK" -f $name) -ForegroundColor Green
    } catch {
        Write-Host ("  {0,-18} : FAIL" -f $name) -ForegroundColor Red
    }
}

switch ($Action) {
    "help"    { Show-Help }
    "start"   { docker compose up -d --build; Show-Banner }
    "stop"    { docker compose stop }
    "restart" { docker compose stop; docker compose up -d --build; Show-Banner }
    "logs"    { docker compose logs -f --tail=100 }
    "ps"      { docker compose ps }
    "status"  { docker compose ps --format "table {{.Name}}`t{{.Status}}`t{{.Ports}}" }
    "clean"   { docker compose down -v; Write-Host "✅ Stack arrêtée et volumes supprimés" -ForegroundColor Yellow }
    "build"   { docker compose build }
    "health"  {
        Write-Host "🔍 Test des endpoints..." -ForegroundColor Cyan
        Test-Endpoint "Frontend"   "http://localhost"
        Test-Endpoint "Backend API" "http://localhost/api/tasks"
        Test-Endpoint "Grafana"    "http://localhost:3000/api/health"
        Test-Endpoint "Prometheus" "http://localhost:9090/-/healthy"
        Test-Endpoint "Loki"       "http://localhost:3100/ready"
        Test-Endpoint "cAdvisor"   "http://localhost:8080/healthz"
    }
    "backup"  {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $file = "backups\webmon_$timestamp.sql"
        docker compose exec -T postgres pg_dump -U webmon webmon | Out-File -Encoding UTF8 $file
        Write-Host "✅ Backup créé : $file" -ForegroundColor Green
    }
    "restore" {
        $latest = Get-ChildItem backups\*.sql | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) { Write-Host "❌ Aucun backup trouvé" -ForegroundColor Red; exit 1 }
        Write-Host "Restauration depuis : $($latest.Name)" -ForegroundColor Yellow
        Get-Content $latest.FullName | docker compose exec -T postgres psql -U webmon -d webmon
        Write-Host "✅ Restauration terminée" -ForegroundColor Green
    }
    "chaos"   {
        $targets = @("webmon-backend", "webmon-frontend", "webmon-nginx")
        $victim = $targets | Get-Random
        Write-Host "💀 Killing $victim" -ForegroundColor Red
        docker kill $victim
        Write-Host "🔍 Observez Grafana : http://localhost:3000" -ForegroundColor Cyan
        Write-Host "⏱  Le conteneur va redémarrer automatiquement (restart: unless-stopped)" -ForegroundColor Yellow
    }
    "stress"  {
        Write-Host "🔥 Génération de charge CPU pendant 30s..." -ForegroundColor Yellow
        docker run --rm -d --name webmon-stress --network webmon_webmon polinux/stress stress --cpu 2 --timeout 30s | Out-Null
        Write-Host "✅ Lancé. Observez Grafana : http://localhost:3000" -ForegroundColor Green
    }
}