#!/bin/bash

# End-to-End Deployment Script
# This script deploys infrastructure with Terraform and application with Kubernetes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_header() {
    echo ""
    echo "==========================================="
    echo "$1"
    echo "==========================================="
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing=0
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        missing=1
    else
        print_info "✓ Terraform: $(terraform version | head -n1)"
    fi
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        missing=1
    else
        print_info "✓ Azure CLI: $(az version --query '\"azure-cli\"' -o tsv)"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        missing=1
    else
        print_info "✓ kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        missing=1
    else
        print_info "✓ Docker: $(docker --version)"
    fi
    
    if [ $missing -eq 1 ]; then
        print_error "Please install missing prerequisites"
        exit 1
    fi
    
    print_info "All prerequisites satisfied"
}

# Check Azure login
check_azure_login() {
    print_step "Checking Azure login..."
    
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure"
        print_info "Please run: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    print_info "Logged in to Azure subscription: $subscription"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_header "DEPLOYING INFRASTRUCTURE WITH TERRAFORM"
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found"
        print_info "Copying from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your values"
        print_info "Then run this script again"
        exit 1
    fi
    
    # Initialize Terraform
    print_step "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    print_step "Validating Terraform configuration..."
    terraform validate
    
    # Plan
    print_step "Planning infrastructure changes..."
    terraform plan -out=tfplan
    
    # Apply
    print_step "Applying Terraform configuration..."
    echo ""
    read -p "Deploy infrastructure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    terraform apply tfplan
    
    print_info "✓ Infrastructure deployed successfully"
    
    cd ..
}

# Get cluster credentials
get_cluster_credentials() {
    print_header "CONFIGURING KUBECTL"
    
    cd terraform
    
    local cluster_name=$(terraform output -raw cluster_name)
    local resource_group=$(terraform output -raw resource_group_name)
    
    print_step "Getting AKS credentials..."
    az aks get-credentials \
        --resource-group "$resource_group" \
        --name "$cluster_name" \
        --overwrite-existing
    
    print_info "✓ kubectl configured"
    
    # Verify connection
    print_step "Verifying cluster connection..."
    kubectl get nodes
    
    cd ..
}

# Build and push Docker image
build_push_image() {
    print_header "BUILDING AND PUSHING DOCKER IMAGE"
    
    cd terraform
    local acr_name=$(terraform output -raw acr_name)
    local acr_login_server=$(terraform output -raw acr_login_server)
    cd ..
    
    # Login to ACR
    print_step "Logging in to Azure Container Registry..."
    az acr login --name "$acr_name"
    
    # Build image
    print_step "Building Docker image..."
    docker build -t flask-video-app:latest .
    
    # Tag image
    print_step "Tagging image..."
    docker tag flask-video-app:latest "${acr_login_server}/flask-video-app:latest"
    
    # Push image
    print_step "Pushing image to ACR..."
    docker push "${acr_login_server}/flask-video-app:latest"
    
    print_info "✓ Image pushed to ${acr_login_server}/flask-video-app:latest"
    
    # Update Kubernetes manifests
    print_step "Updating Kubernetes manifests..."
    
    # Backup original
    cp k8s/deployment.yaml k8s/deployment.yaml.bak
    cp k8s/all-in-one.yaml k8s/all-in-one.yaml.bak
    
    # Update image in manifests
    sed -i.tmp "s|image: flask-video-app:latest|image: ${acr_login_server}/flask-video-app:latest|g" k8s/deployment.yaml
    sed -i.tmp "s|image: flask-video-app:latest|image: ${acr_login_server}/flask-video-app:latest|g" k8s/all-in-one.yaml
    rm k8s/*.tmp
    
    print_info "✓ Kubernetes manifests updated"
}

# Deploy application to Kubernetes
deploy_application() {
    print_header "DEPLOYING APPLICATION TO KUBERNETES"
    
    print_step "Deploying resources..."
    kubectl apply -f k8s/all-in-one.yaml
    
    print_step "Waiting for deployment to be ready..."
    kubectl rollout status deployment/flask-video-streaming -n flask-video-streaming --timeout=5m
    
    print_info "✓ Application deployed successfully"
}

# Get application URL
get_application_url() {
    print_header "APPLICATION ACCESS"
    
    print_step "Waiting for LoadBalancer IP..."
    
    local count=0
    local max_attempts=24
    local external_ip=""
    
    while [ $count -lt $max_attempts ]; do
        external_ip=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -z "$external_ip" ]; then
            external_ip=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        fi
        
        if [ -n "$external_ip" ] && [ "$external_ip" != "<pending>" ]; then
            echo ""
            print_info "LoadBalancer External IP: $external_ip"
            echo ""
            echo "================================================================"
            echo "                   DEPLOYMENT SUCCESSFUL!"
            echo "================================================================"
            echo ""
            echo "  Access your application at:"
            echo "  → http://${external_ip}"
            echo ""
            echo "  Useful commands:"
            echo "  → View pods:    kubectl get pods -n flask-video-streaming"
            echo "  → View logs:    kubectl logs -l app=flask-video-streaming -n flask-video-streaming -f"
            echo "  → View service: kubectl get svc -n flask-video-streaming"
            echo "  → Scale app:    kubectl scale deployment flask-video-streaming --replicas=5 -n flask-video-streaming"
            echo ""
            echo "================================================================"
            echo ""
            return 0
        fi
        
        echo -n "."
        sleep 5
        count=$((count + 1))
    done
    
    echo ""
    print_warning "LoadBalancer IP not assigned yet"
    print_info "Run the following to check:"
    echo "  kubectl get service flask-video-streaming -n flask-video-streaming"
}

# Show deployment summary
show_summary() {
    print_header "DEPLOYMENT SUMMARY"
    
    cd terraform
    
    echo "Infrastructure:"
    terraform output deployment_summary
    
    echo ""
    echo "Kubernetes Resources:"
    kubectl get all -n flask-video-streaming
    
    cd ..
}

# Cleanup function
cleanup() {
    print_header "CLEANUP"
    
    print_warning "This will destroy all infrastructure and resources"
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
    
    # Delete Kubernetes resources
    print_step "Deleting Kubernetes resources..."
    kubectl delete namespace flask-video-streaming --ignore-not-found=true
    
    # Destroy Terraform infrastructure
    print_step "Destroying Terraform infrastructure..."
    cd terraform
    terraform destroy
    cd ..
    
    print_info "✓ Cleanup complete"
}

# Main menu
show_menu() {
    echo ""
    echo "==========================================="
    echo "Flask Video Streaming - Full Deployment"
    echo "==========================================="
    echo "1. Full Deployment (Infrastructure + Application)"
    echo "2. Deploy Infrastructure Only (Terraform)"
    echo "3. Deploy Application Only (Kubernetes)"
    echo "4. Build and Push Docker Image"
    echo "5. Get Application URL"
    echo "6. Show Deployment Summary"
    echo "7. Cleanup (Destroy Everything)"
    echo "8. Exit"
    echo ""
}

# Interactive mode
interactive_mode() {
    check_prerequisites
    check_azure_login
    
    while true; do
        show_menu
        read -p "Select an option (1-8): " choice
        
        case $choice in
            1)
                deploy_infrastructure
                get_cluster_credentials
                build_push_image
                deploy_application
                get_application_url
                show_summary
                ;;
            2)
                deploy_infrastructure
                get_cluster_credentials
                ;;
            3)
                get_cluster_credentials
                deploy_application
                get_application_url
                ;;
            4)
                build_push_image
                ;;
            5)
                get_application_url
                ;;
            6)
                show_summary
                ;;
            7)
                cleanup
                ;;
            8)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Parse command line arguments
case "${1:-}" in
    full)
        check_prerequisites
        check_azure_login
        deploy_infrastructure
        get_cluster_credentials
        build_push_image
        deploy_application
        get_application_url
        show_summary
        ;;
    infra)
        check_prerequisites
        check_azure_login
        deploy_infrastructure
        get_cluster_credentials
        ;;
    app)
        check_prerequisites
        check_azure_login
        get_cluster_credentials
        deploy_application
        get_application_url
        ;;
    build)
        check_prerequisites
        check_azure_login
        build_push_image
        ;;
    cleanup)
        check_prerequisites
        check_azure_login
        cleanup
        ;;
    --help|-h)
        echo "Flask Video Streaming - Full Deployment Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  full     - Full deployment (infrastructure + application)"
        echo "  infra    - Deploy infrastructure only"
        echo "  app      - Deploy application only"
        echo "  build    - Build and push Docker image"
        echo "  cleanup  - Destroy all resources"
        echo ""
        echo "If no command is provided, interactive mode will start."
        ;;
    "")
        interactive_mode
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 --help' for usage information"
        exit 1
        ;;
esac
