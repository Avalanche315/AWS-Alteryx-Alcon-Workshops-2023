# Set the path var
$path = Get-Location
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