# Auto-detect IP and start mobile test server
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  Nagarsevak Mobile - Local Phone Test Server" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# 1. Kill any existing process on port 8000
Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }

# 2. Always build latest web assets
Write-Host "[1/2] Compiling Flutter Web with latest Drawer & Schemes UI..." -ForegroundColor Yellow
flutter build web

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Flutter build web failed! Check the error above." -ForegroundColor Red
    pause
    exit $LASTEXITCODE
}

# 3. Get local IPv4 address
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    ($_.InterfaceAlias -match 'Wi-Fi|Wireless|Ethernet|Local Area') -and 
    ($_.IPAddress -notmatch '^127\.|^169\.254\.') 
} | Select-Object -ExpandProperty IPAddress -First 1)

if (-not $ip) {
    $ip = (ipconfig | Select-String -Pattern "IPv4 Address[ .]*: ([\d\.]+)" | ForEach-Object { $_.Matches.Groups[1].Value } | Select-Object -First 1)
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  >>> YOUR MOBILE TEST LINK (OPEN IN INCOGNITO TAB):" -ForegroundColor Yellow
Write-Host "      http://$($ip):8000" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Make sure your mobile phone is connected to the SAME Wi-Fi" -ForegroundColor Gray
Write-Host "  Use an Incognito / Private tab to bypass browser caching" -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop the server.`n" -ForegroundColor Gray

# 4. Serve build/web
Set-Location "build\web"
python -m http.server 8000 --bind 0.0.0.0
