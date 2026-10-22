# deploy-backend.ps1
# Deploys the micro-blogging CDK stack.
# Used by students to redeploy after making changes (e.g., adding a new feature).
$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "backend"
$InfrastructureDir = Join-Path $ScriptDir "infrastructure"

# Stack name (can be overridden via environment variable)
$StackName = if ($env:STACK_NAME) { $env:STACK_NAME } else { "AppStack" }

Write-Host "Starting backend deployment..." -ForegroundColor Cyan
Write-Host "Stack name: $StackName" -ForegroundColor Cyan

# Navigate to the backend directory
Set-Location $BackendDir

# Install dependencies if needed
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
npm install

# Build the backend (Windows-compatible: copy src to dist, remove .ts files)
Write-Host "Building backend..." -ForegroundColor Yellow
$distDir = Join-Path $BackendDir "dist"
if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
}
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $BackendDir "src\*") $distDir
Get-ChildItem -Recurse -Path $distDir -Filter "*.ts" | Remove-Item -Force

# Prepare Lambda packages with dependencies
Write-Host "Preparing Lambda packages with dependencies..." -ForegroundColor Yellow
& "$BackendDir\scripts\prepare-lambda-packages.ps1"

# Navigate to infrastructure directory
Set-Location $InfrastructureDir

# Install dependencies if needed
Write-Host "Installing infrastructure dependencies..." -ForegroundColor Yellow
npm install

# Build the infrastructure code
Write-Host "Building infrastructure code..." -ForegroundColor Yellow
npm run build

# Deploy backend infrastructure using CDK
Write-Host "Deploying backend infrastructure..." -ForegroundColor Yellow

# Note: CDK bootstrap is pre-configured in the lab environment.
# Do NOT run "cdk bootstrap" directly - it will fail.
cdk deploy $StackName --require-approval never

Write-Host "Backend deployment completed successfully!" -ForegroundColor Green
