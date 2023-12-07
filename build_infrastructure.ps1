# Set the path var
$path = Get-Location

# If there is no dist dir - create it
if (-not (Test-Path "$path\dist")) {
    New-Item -ItemType Directory -Path "$path\dist" | Out-Null
}

# Build .zip for AWS Lambda
Compress-Archive -Path "$path\src" -DestinationPath "$path\dist\lambda_code.zip" -Force

# Terraform
# If there is no .terraform dir - init terraform
if (-not (Test-Path "$path\.terraform")) {
    terraform init
}

# Create all resources
terraform plan -out "$path\dist\plan.out"
terraform apply "$path\dist\plan.out"

# NOTE: For Windows, run it with following command: 
# powershell.exe -ExecutionPolicy Unrestricted -File .\build_infrastructure.ps1