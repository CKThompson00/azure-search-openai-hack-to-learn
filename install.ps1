Write-Host ""
Write-Host "Running Bicep Deployment..."
Write-Host ""

Write-Host "Enter the region you wish to deploy to:"
$region = (Read-Host).ToUpper()

Write-Host "Enter the environment name:"
$environment = (Read-Host).ToLower()

Write-Host "Enter the principalId:"
$principalId = Read-Host

Write-Host ""
Write-Host "Deploying resources..."
Write-Host ""

az deployment sub create --template-file ./infra/main.bicep --location $region --parameters location=$region environmentName=$environment principalId=$principalId > bicepoutput.json

$content = Get-Content -Raw -Path bicepoutput.json
$json_output = $content | ConvertFrom-Json

[Environment]::SetEnvironmentVariable("AZURE_FORMRECOGNIZER_RESOURCE_GROUP", $json_output.properties.outputs.AZURE_FORMRECOGNIZER_RESOURCE_GROUP.value)
[Environment]::SetEnvironmentVariable("AZURE_FORMRECOGNIZER_SERVICE", $json_output.properties.outputs.AZURE_FORMRECOGNIZER_SERVICE.value)
[Environment]::SetEnvironmentVariable("AZURE_LOCATION", $json_output.properties.outputs.AZURE_LOCATION.value)
[Environment]::SetEnvironmentVariable("AZURE_OPENAI_CHATGPT_DEPLOYMENT", $json_output.properties.outputs.AZURE_OPENAI_CHATGPT_DEPLOYMENT.value)
[Environment]::SetEnvironmentVariable("AZURE_OPENAI_GPT_DEPLOYMENT", $json_output.properties.outputs.AZURE_OPENAI_GPT_DEPLOYMENT.value)
[Environment]::SetEnvironmentVariable("AZURE_OPENAI_RESOURCE_GROUP", $json_output.properties.outputs.AZURE_OPENAI_RESOURCE_GROUP.value)
[Environment]::SetEnvironmentVariable("AZURE_OPENAI_SERVICE", $json_output.properties.outputs.AZURE_OPENAI_SERVICE.value)
[Environment]::SetEnvironmentVariable("AZURE_RESOURCE_GROUP", $json_output.properties.outputs.AZURE_RESOURCE_GROUP.value)
[Environment]::SetEnvironmentVariable("AZURE_SEARCH_INDEX", $json_output.properties.outputs.AZURE_SEARCH_INDEX.value)
[Environment]::SetEnvironmentVariable("AZURE_SEARCH_SERVICE", $json_output.properties.outputs.AZURE_SEARCH_SERVICE.value)
[Environment]::SetEnvironmentVariable("AZURE_SEARCH_SERVICE_RESOURCE_GROUP", $json_output.properties.outputs.AZURE_SEARCH_SERVICE_RESOURCE_GROUP.value)
[Environment]::SetEnvironmentVariable("AZURE_STORAGE_ACCOUNT", $json_output.properties.outputs.AZURE_STORAGE_ACCOUNT.value)
[Environment]::SetEnvironmentVariable("AZURE_STORAGE_CONTAINER", $json_output.properties.outputs.AZURE_STORAGE_CONTAINER.value)
[Environment]::SetEnvironmentVariable("AZURE_STORAGE_RESOURCE_GROUP", $json_output.properties.outputs.AZURE_STORAGE_RESOURCE_GROUP.value)
[Environment]::SetEnvironmentVariable("AZURE_TENANT_ID", $json_output.properties.outputs.AZURE_TENANT_ID.value)
[Environment]::SetEnvironmentVariable("BACKEND_URI", $json_output.properties.outputs.BACKEND_URI.value)
[Environment]::SetEnvironmentVariable("AZURE_BACKEND_SERVICE_NAME", $json_output.properties.outputs.AZURE_BACKEND_SERVICE_NAME.value)

Write-Host "Environment variables set."

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # fallback to python3 if python not found
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}

Write-Host 'Creating python virtual environment "scripts/.venv"'
Start-Process -FilePath ($pythonCmd).Source -ArgumentList "-m venv ./scripts/.venv" -Wait -NoNewWindow

$venvPythonPath = "./scripts/.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./scripts/.venv/bin/python"
}

Write-Host 'Installing dependencies from "requirements.txt" into virtual environment'
Start-Process -FilePath $venvPythonPath -ArgumentList "-m pip install -r ./scripts/requirements.txt" -Wait -NoNewWindow

Write-Host 'Running "prepdocs.py"'
$cwd = (Get-Location)
Start-Process -FilePath $venvPythonPath -ArgumentList "./scripts/prepdocs.py $cwd/data/* --storageaccount $env:AZURE_STORAGE_ACCOUNT --container $env:AZURE_STORAGE_CONTAINER --searchservice $env:AZURE_SEARCH_SERVICE --index $env:AZURE_SEARCH_INDEX --formrecognizerservice $env:AZURE_FORMRECOGNIZER_SERVICE --tenantid $env:AZURE_TENANT_ID -v" -Wait -NoNewWindow


Set-Location "app/frontend"
npm install
npm run build

Set-Location "../backend"
Compress-Archive -Path * -DestinationPath ../../backend.zip -Force
Write-Output $env:AZURE_BACKEND_SERVICE_NAME
az webapp deploy --resource-group $env:AZURE_OPENAI_RESOURCE_GROUP --name $env:AZURE_BACKEND_SERVICE_NAME --src-path backend.zip --type zip --async true
