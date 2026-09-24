param(
    [switch]$Build,
    [switch]$Fix
)

$ErrorActionPreference = 'Stop'

# Auto-detect Flutter SDK path if not in system PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\src\flutter\bin") {
        $env:Path = "C:\src\flutter\bin;$env:Path"
    }
}

$failed = @()

function Step($name, $block) {
    Write-Host ""
    Write-Host "-- $name " -NoNewline -ForegroundColor Cyan
    Write-Host ("-" * [Math]::Max(0, 60 - $name.Length)) -ForegroundColor DarkGray
    & $block
    if ($LASTEXITCODE -ne 0) {
        $script:failed += $name
        Write-Host "FAIL: $name" -ForegroundColor Red
    }
    else {
        Write-Host "PASS: $name" -ForegroundColor Green
    }
}

Step "pub get" { flutter pub get }

if ($Fix) {
    Step "format (auto-fix)" { dart format . }
}
else {
    Step "format check" { dart format --output=none --set-exit-if-changed . }
}

Step "analyze" { flutter analyze --no-fatal-infos }

Step "test + coverage" { flutter test --coverage --reporter expanded }

Step "critical-path coverage" { dart run tool/check_coverage.dart }

if ($Build) {
    if (-not (Test-Path ".env")) {
        Write-Host "SKIPPED: build (.env not found)" -ForegroundColor Yellow
    }
    else {
        Step "build debug apk" {
            flutter build apk --debug `
                --dart-define-from-file=.env `
                --dart-define=APP_ENV=dev `
                --dart-define=COMMIT_SHA=local
        }
    }
}

Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "Everything green. Safe to push." -ForegroundColor Green
    exit 0
}

Write-Host "FAILED: $($failed -join ', ')" -ForegroundColor Red
exit 1