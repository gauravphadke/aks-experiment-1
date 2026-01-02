#!/bin/bash

# Kubernetes Deployment Script for Flask Video Streaming App
# This script helps deploy the application to a Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        echo "Visit: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    print_info "kubectl found: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
}

# Check cluster connectivity
check_cluster() {
    print_step "Checking Kubernetes cluster connectivity..."
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster."
        echo "Please ensure:"
        echo "  1. Your kubeconfig is properly configured"
        echo "  2. You have access to the cluster"
        echo "  3. The cluster is running"
        exit 1
    fi
    print_info "Connected to cluster: $(kubectl config current-context)"
}

# Build Docker image
build_image() {
    print_step "Building Docker image..."
    
    cd "$(dirname "$0")/.." || exit 1
    
    if [ -f "Dockerfile" ]; then
        docker build -t flask-video-app:latest .
        print_info "✓ Docker image built successfully"
    else
        print_error "Dockerfile not found"
        exit 1
    fi
}

# Tag and push image to registry
push_image() {
    local registry=$1
    
    if [ -z "$registry" ]; then
        print_warning "No registry specified. Image will only be available locally."
        print_warning "For production, push to a container registry (ACR, ECR, GCR, Docker Hub)"
        return 0
    fi
    
    print_step "Tagging and pushing image to registry..."
    
    local image_name="${registry}/flask-video-app:latest"
    docker tag flask-video-app:latest "$image_name"
    docker push "$image_name"
    
    print_info "✓ Image pushed to $image_name"
    
    # Update deployment to use registry image
    sed -i.bak "s|image: flask-video-app:latest|image: ${image_name}|g" k8s/deployment.yaml
    sed -i.bak "s|image: flask-video-app:latest|image: ${image_name}|g" k8s/all-in-one.yaml
}

# Deploy namespace
deploy_namespace() {
    print_step "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    print_info "✓ Namespace created/updated"
}

# Deploy using individual files
deploy_individual() {
    print_step "Deploying resources individually..."
    
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/hpa.yaml
    kubectl apply -f k8s/pdb.yaml
    kubectl apply -f k8s/resourcequota.yaml
    
    print_info "✓ All resources deployed"
}

# Deploy using all-in-one file
deploy_all_in_one() {
    print_step "Deploying all resources from all-in-one.yaml..."
    
    kubectl apply -f k8s/all-in-one.yaml
    
    print_info "✓ All resources deployed"
}

# Deploy using Kustomize
deploy_kustomize() {
    print_step "Deploying using Kustomize..."
    
    if ! command -v kustomize &> /dev/null; then
        print_warning "Kustomize not found, using kubectl kustomize..."
        kubectl apply -k k8s/
    else
        kustomize build k8s/ | kubectl apply -f -
    fi
    
    print_info "✓ Deployed via Kustomize"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_step "Waiting for deployment to be ready..."
    
    kubectl rollout status deployment/flask-video-streaming -n flask-video-streaming --timeout=5m
    
    print_info "✓ Deployment is ready"
}

# Get service information
get_service_info() {
    print_step "Getting service information..."
    
    echo ""
    echo "Service Details:"
    kubectl get service flask-video-streaming -n flask-video-streaming
    
    echo ""
    echo "Waiting for LoadBalancer IP..."
    
    # Wait for external IP (max 2 minutes)
    local count=0
    local max_attempts=24
    
    while [ $count -lt $max_attempts ]; do
        EXTERNAL_IP=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -z "$EXTERNAL_IP" ]; then
            EXTERNAL_IP=$(kubectl get service flask-video-streaming -n flask-video-streaming -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        fi
        
        if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "<pending>" ]; then
            echo ""
            print_info "LoadBalancer External IP: $EXTERNAL_IP"
            echo ""
            echo "Access your application at:"
            echo "  → http://${EXTERNAL_IP}"
            echo ""
            return 0
        fi
        
        echo -n "."
        sleep 5
        count=$((count + 1))
    done
    
    echo ""
    print_warning "LoadBalancer IP not assigned yet. Run the following to check:"
    echo "  kubectl get service flask-video-streaming -n flask-video-streaming"
}

# Show deployment status
show_status() {
    print_step "Deployment Status"
    
    echo ""
    echo "Pods:"
    kubectl get pods -n flask-video-streaming -o wide
    
    echo ""
    echo "Service:"
    kubectl get service flask-video-streaming -n flask-video-streaming
    
    echo ""
    echo "HPA Status:"
    kubectl get hpa -n flask-video-streaming
    
    echo ""
    echo "PDB Status:"
    kubectl get pdb -n flask-video-streaming
}

# Delete deployment
delete_deployment() {
    print_warning "This will delete all resources in the flask-video-streaming namespace."
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deletion cancelled"
        return 0
    fi
    
    print_step "Deleting all resources..."
    
    kubectl delete namespace flask-video-streaming
    
    print_info "✓ All resources deleted"
}

# Show logs
show_logs() {
    print_step "Showing logs from pods..."
    
    echo "Available pods:"
    kubectl get pods -n flask-video-streaming -o name
    
    echo ""
    read -p "Enter pod name (or press Enter for all pods): " pod_name
    
    if [ -z "$pod_name" ]; then
        kubectl logs -n flask-video-streaming -l app=flask-video-streaming --tail=100 -f
    else
        kubectl logs -n flask-video-streaming "$pod_name" --tail=100 -f
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "========================================"
    echo "Flask Video Streaming - K8s Deployment"
    echo "========================================"
    echo "1. Full Deployment (Build + Deploy)"
    echo "2. Build Docker Image Only"
    echo "3. Deploy to Kubernetes (All-in-One)"
    echo "4. Deploy to Kubernetes (Individual Files)"
    echo "5. Deploy with Kustomize"
    echo "6. Check Deployment Status"
    echo "7. View Logs"
    echo "8. Delete Deployment"
    echo "9. Exit"
    echo ""
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Select an option (1-9): " choice
        
        case $choice in
            1)
                check_kubectl
                check_cluster
                build_image
                deploy_all_in_one
                wait_for_deployment
                get_service_info
                show_status
                ;;
            2)
                build_image
                ;;
            3)
                check_kubectl
                check_cluster
                deploy_all_in_one
                wait_for_deployment
                get_service_info
                show_status
                ;;
            4)
                check_kubectl
                check_cluster
                deploy_individual
                wait_for_deployment
                get_service_info
                show_status
                ;;
            5)
                check_kubectl
                check_cluster
                deploy_kustomize
                wait_for_deployment
                get_service_info
                show_status
                ;;
            6)
                check_kubectl
                show_status
                get_service_info
                ;;
            7)
                check_kubectl
                show_logs
                ;;
            8)
                check_kubectl
                delete_deployment
                ;;
            9)
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
    build)
        build_image
        ;;
    deploy)
        check_kubectl
        check_cluster
        deploy_all_in_one
        wait_for_deployment
        get_service_info
        show_status
        ;;
    full)
        check_kubectl
        check_cluster
        build_image
        deploy_all_in_one
        wait_for_deployment
        get_service_info
        show_status
        ;;
    delete)
        check_kubectl
        delete_deployment
        ;;
    status)
        check_kubectl
        show_status
        get_service_info
        ;;
    logs)
        check_kubectl
        show_logs
        ;;
    --help|-h)
        echo "Flask Video Streaming - Kubernetes Deployment"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build    - Build Docker image"
        echo "  deploy   - Deploy to Kubernetes"
        echo "  full     - Build and deploy (full deployment)"
        echo "  delete   - Delete deployment"
        echo "  status   - Check deployment status"
        echo "  logs     - View pod logs"
        echo ""
        echo "If no command is provided, interactive mode will start."
        ;;
    "")
        check_kubectl
        check_cluster
        interactive_mode
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 --help' for usage information"
        exit 1
        ;;
esac
