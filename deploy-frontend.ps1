# deploy-frontend.ps1
# Builds the React frontend and deploys it to the live S3 + CloudFront environment.
# Use this after making frontend changes to update the live application.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FrontendDir = Join-Path $ScriptDir "frontend"
$StackName = if ($env:STACK_NAME) { $env:STACK_NAME } else { "AppStack" }

Write-Host "Starting frontend deployment..." -ForegroundColor Cyan

# Retrieve stack outputs (bucket name and distribution ID)
Write-Host "Retrieving stack outputs..." -ForegroundColor Yellow
$stackOutputs = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs" --output json | ConvertFrom-Json

$websiteBucketName = ($stackOutputs | Where-Object { $_.OutputKey -eq "WebsiteBucketName" }).OutputValue
$distributionId = ($stackOutputs | Where-Object { $_.OutputKey -eq "CloudFrontDistributionId" }).OutputValue

if ([string]::IsNullOrWhiteSpace($websiteBucketName)) {
    throw "WebsiteBucketName not found in $StackName outputs. Is the stack deployed?"
}

Write-Host "Website bucket: $websiteBucketName" -ForegroundColor Cyan
Write-Host "Distribution ID: $distributionId" -ForegroundColor Cyan

# Build the frontend
Write-Host "Building frontend..." -ForegroundColor Yellow
Set-Location $FrontendDir
npm install
npm run build

# Upload to S3
Write-Host "Uploading to S3..." -ForegroundColor Yellow
aws s3 sync "$FrontendDir\dist" "s3://$websiteBucketName" --delete

# Invalidate CloudFront cache
if (-not [string]::IsNullOrWhiteSpace($distributionId)) {
    Write-Host "Invalidating CloudFront cache..." -ForegroundColor Yellow
    aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*" | Out-Null
    Write-Host "CloudFront invalidation initiated. Changes may take 1-2 minutes to propagate." -ForegroundColor Cyan
}

Write-Host "Frontend deployment completed successfully!" -ForegroundColor Green
