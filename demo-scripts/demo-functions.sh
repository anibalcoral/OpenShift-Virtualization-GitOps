#!/bin/bash

# Common functions for demo scripts

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Function to wait for a specific sync status
wait_for_sync_status() {
    local app_name="$1"
    local expected_status="$2"
    local max_wait="${3:-60}"
    local namespace="${4:-openshift-gitops}"
    
    log "Waiting for application '$app_name' to reach sync status '$expected_status'..."
    
    for i in $(seq 1 $max_wait); do
        local current_status=$(oc get applications.argoproj.io $app_name -n $namespace -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        
        if [ "$current_status" = "$expected_status" ]; then
            log_success "Application '$app_name' is now '$expected_status'"
            return 0
        fi
        
        log "Current status: $current_status, waiting for: $expected_status... ($i/$max_wait)"
        sleep 5
    done
    
    log_error "Timeout waiting for application '$app_name' to reach status '$expected_status'"
    return 1
}

# Function to wait for a specific health status
wait_for_health_status() {
    local app_name="$1"
    local expected_status="$2"
    local max_wait="${3:-60}"
    local namespace="${4:-openshift-gitops}"
    
    log "Waiting for application '$app_name' to reach health status '$expected_status'..."
    
    for i in $(seq 1 $max_wait); do
        local current_status=$(oc get applications.argoproj.io $app_name -n $namespace -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        
        if [ "$current_status" = "$expected_status" ]; then
            log_success "Application '$app_name' health is now '$expected_status'"
            return 0
        fi
        
        log "Current health: $current_status, waiting for: $expected_status... ($i/$max_wait)"
        sleep 5
    done
    
    log_error "Timeout waiting for application '$app_name' to reach health status '$expected_status'"
    return 1
}

# Function to wait for VM to exist
wait_for_vm_exists() {
    local vm_name="$1"
    local namespace="$2"
    local max_wait="${3:-60}"
    
    log "Waiting for VM '$vm_name' to exist in namespace '$namespace'..."
    
    for i in $(seq 1 $max_wait); do
        if oc get vm $vm_name -n $namespace &>/dev/null; then
            log_success "VM '$vm_name' exists"
            return 0
        fi
        
        log "Waiting for VM '$vm_name' to be created... ($i/$max_wait)"
        sleep 5
    done
    
    log_error "Timeout waiting for VM '$vm_name' to be created"
    return 1
}

# Function to wait for VM to be deleted
wait_for_vm_deleted() {
    local vm_name="$1"
    local namespace="$2"
    local max_wait="${3:-60}"
    
    log "Waiting for VM '$vm_name' to be deleted from namespace '$namespace'..."
    
    for i in $(seq 1 $max_wait); do
        if ! oc get vm $vm_name -n $namespace &>/dev/null; then
            log_success "VM '$vm_name' has been deleted"
            return 0
        fi
        
        log "Waiting for VM '$vm_name' to be deleted... ($i/$max_wait)"
        sleep 5
    done
    
    log_error "Timeout waiting for VM '$vm_name' to be deleted"
    return 1
}

# Function to trigger ArgoCD sync manually
trigger_sync() {
    local app_name="$1"
    local namespace="${2:-openshift-gitops}"
    
    log "Triggering manual sync for application '$app_name'..."
    
    oc patch applications.argoproj.io $app_name -n $namespace \
        --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}' &>/dev/null || true
    
    # Alternative method using annotation
    oc annotate applications.argoproj.io $app_name -n $namespace \
        argocd.argoproj.io/refresh="$(date)" --overwrite &>/dev/null || true
        
    log_success "Sync triggered for application '$app_name'"
}

# Function to display current application status
show_app_status() {
    local app_name="$1"
    local namespace="${2:-openshift-gitops}"
    
    local sync_status=$(oc get applications.argoproj.io $app_name -n $namespace -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    local health_status=$(oc get applications.argoproj.io $app_name -n $namespace -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    log "Application '$app_name' status: Sync=$sync_status, Health=$health_status"
}