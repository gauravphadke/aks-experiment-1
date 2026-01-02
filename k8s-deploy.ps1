# Kubernetes Deployment Script for Flask Video Streaming App (Windows PowerShell)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Blue
}

function Check-Kubectl {
    Write-Step "Checking kubectl installation..."
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-ErrorMsg "kubectl is not installed. Please install kubectl first."
        Write-Host "Visit: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    }
    
    $version = kubectl version --client --short 2>$null
    if (-not $version) {
        $version = kubectl version --client 2>$null
    }
    Write-Info "kubectl found: $version"
}

function Check-Cluster {
    Write-Step "Checking Kubernetes cluster connectivity..."
    
    try {
        kubectl cluster-info 2>&1 | Out-Null
        $context = kubectl config current-context 2>$null
        Write-Info "Connected to cluster: $context"
    }
    catch {
        Write-ErrorMsg "Cannot connect to Kubernetes cluster."
        Write-Host "Please ensure:"
        Write-Host "  1. Your kubeconfig is properly configured"
        Write-Host "  2. You have access to the cluster"
        Write-Host "  3. The cluster is running"
        exit 1
    }
}

function Build-Image {
    Write-Step "Building Docker image..."
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    Push-Location $scriptPath
    
    if (Test-Path "Dockerfile") {
        docker build -t flask-video-app:latest .
        if ($LASTEXITCODE -eq 0) {
            Write-Info "✓ Docker image built successfully"
        }
        else {
            Write-ErrorMsg "Docker build failed"
            exit 1
        }
    }
    else {
        Write-ErrorMsg "Dockerfile not found"
        exit 1
    }
    
    Pop-Location
}

function Deploy-AllInOne {
    Write-Step "Deploying all resources from all-in-one.yaml..."
    
    kubectl apply -f k8s/all-in-one.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "✓ All resources deployed"
    }
    else {
        Write-ErrorMsg "Deployment failed"
        exit 1
    }
}

function Deploy-Individual {
    Write-Step "Deploying resources individually..."
    
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/hpa.yaml
    kubectl apply -f k8s/pdb.yaml
    kubectl apply -f k8s/resourcequota.yaml
    
    Write-Info "✓ All resources deployed"
}

function Wait-ForDeployment {
    Write-Step "Waiting for deployment to be ready..."
    
    kubectl rollout status deployment/flask-video-streaming -n flask-video-streaming --timeout=5m
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "✓ Deployment is ready"
    }
}

function Get-ServiceInfo {
    Write-Step "Getting service information..."
    
    Write-Host ""
    Write-Host "Service Details:"
    kubectl get service flask-video-streaming -n flask-video-streaming
    
    Write-Host ""
    Write-Host "Waiting for LoadBalancer IP..."
    
    $maxAttempts = 24
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        $externalIP = kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        
        if (-not $externalIP) {
            $externalIP = kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
        }
        
        if ($externalIP -and $externalIP -ne "<pending>") {
            Write-Host ""
            Write-Info "LoadBalancer External IP: $externalIP"
            Write-Host ""
            Write-Host "Access your application at:"
            Write-Host "  → http://$externalIP"
            Write-Host ""
            return
        }
        
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 5
        $attempt++
    }
    
    Write-Host ""
    Write-Warning "LoadBalancer IP not assigned yet. Run the following to check:"
    Write-Host "  kubectl get service flask-video-streaming -n flask-video-streaming"
}

function Show-Status {
    Write-Step "Deployment Status"
    
    Write-Host ""
    Write-Host "Pods:"
    kubectl get pods -n flask-video-streaming -o wide
    
    Write-Host ""
    Write-Host "Service:"
    kubectl get service flask-video-streaming -n flask-video-streaming
    
    Write-Host ""
    Write-Host "HPA Status:"
    kubectl get hpa -n flask-video-streaming
    
    Write-Host ""
    Write-Host "PDB Status:"
    kubectl get pdb -n flask-video-streaming
}

function Remove-Deployment {
    Write-Warning "This will delete all resources in the flask-video-streaming namespace."
    $confirm = Read-Host "Are you sure? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Info "Deletion cancelled"
        return
    }
    
    Write-Step "Deleting all resources..."
    
    kubectl delete namespace flask-video-streaming
    
    Write-Info "✓ All resources deleted"
}

function Show-Logs {
    Write-Step "Showing logs from pods..."
    
    Write-Host "Available pods:"
    kubectl get pods -n flask-video-streaming -o name
    
    Write-Host ""
    $podName = Read-Host "Enter pod name (or press Enter for all pods)"
    
    if ([string]::IsNullOrWhiteSpace($podName)) {
        kubectl logs -n flask-video-streaming -l app=flask-video-streaming --tail=100 -f
    }
    else {
        kubectl logs -n flask-video-streaming $podName --tail=100 -f
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Flask Video Streaming - K8s Deployment"
    Write-Host "========================================"
    Write-Host "1. Full Deployment (Build + Deploy)"
    Write-Host "2. Build Docker Image Only"
    Write-Host "3. Deploy to Kubernetes (All-in-One)"
    Write-Host "4. Deploy to Kubernetes (Individual Files)"
    Write-Host "5. Check Deployment Status"
    Write-Host "6. View Logs"
    Write-Host "7. Delete Deployment"
    Write-Host "8. Exit"
    Write-Host ""
}

function Interactive-Mode {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select an option (1-8)"
        
        switch ($choice) {
            "1" {
                Check-Kubectl
                Check-Cluster
                Build-Image
                Deploy-AllInOne
                Wait-ForDeployment
                Get-ServiceInfo
                Show-Status
            }
            "2" {
                Build-Image
            }
            "3" {
                Check-Kubectl
                Check-Cluster
                Deploy-AllInOne
                Wait-ForDeployment
                Get-ServiceInfo
                Show-Status
            }
            "4" {
                Check-Kubectl
                Check-Cluster
                Deploy-Individual
                Wait-ForDeployment
                Get-ServiceInfo
                Show-Status
            }
            "5" {
                Check-Kubectl
                Show-Status
                Get-ServiceInfo
            }
            "6" {
                Check-Kubectl
                Show-Logs
            }
            "7" {
                Check-Kubectl
                Remove-Deployment
            }
            "8" {
                Write-Info "Goodbye!"
                exit 0
            }
            default {
                Write-ErrorMsg "Invalid option"
            }
        }
        
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
}

# Main script logic
if ($args.Count -eq 0) {
    Check-Kubectl
    Check-Cluster
    Interactive-Mode
}
else {
    switch ($args[0]) {
        "build" {
            Build-Image
        }
        "deploy" {
            Check-Kubectl
            Check-Cluster
            Deploy-AllInOne
            Wait-ForDeployment
            Get-ServiceInfo
            Show-Status
        }
        "full" {
            Check-Kubectl
            Check-Cluster
            Build-Image
            Deploy-AllInOne
            Wait-ForDeployment
            Get-ServiceInfo
            Show-Status
        }
        "delete" {
            Check-Kubectl
            Remove-Deployment
        }
        "status" {
            Check-Kubectl
            Show-Status
            Get-ServiceInfo
        }
        "logs" {
            Check-Kubectl
            Show-Logs
        }
        default {
            Write-Host "Flask Video Streaming - Kubernetes Deployment"
            Write-Host ""
            Write-Host "Usage: .\k8s-deploy.ps1 [command]"
            Write-Host ""
            Write-Host "Commands:"
            Write-Host "  build    - Build Docker image"
            Write-Host "  deploy   - Deploy to Kubernetes"
            Write-Host "  full     - Build and deploy (full deployment)"
            Write-Host "  delete   - Delete deployment"
            Write-Host "  status   - Check deployment status"
            Write-Host "  logs     - View pod logs"
            Write-Host ""
            Write-Host "If no command is provided, interactive mode will start."
        }
    }
}
