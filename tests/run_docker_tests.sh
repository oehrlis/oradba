#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: run_docker_tests.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.01.15
# Revision...: 1.0.0
# Purpose....: Wrapper to run OraDBA automated tests in Docker container
# Notes......: Starts Oracle 26ai Free container and runs tests
# Usage......: ./run_docker_tests.sh [--keep-container] [--no-build]
# Reference..: https://github.com/oehrlis/oradba
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Docker configuration
DOCKER_IMAGE="${ORADBA_TEST_IMAGE:-container-registry.oracle.com/database/free:latest}"
CONTAINER_NAME="oradba-test-$(date +%s)"
KEEP_CONTAINER=false
RUN_BUILD=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Run OraDBA automated tests in Oracle 26ai Free Docker container.

OPTIONS:
    --keep-container    Keep container running after tests
    --no-build          Skip 'make build' step
    --image IMAGE       Use specific Docker image (default: oracle/database:23-free)
    --help              Show this help message

ENVIRONMENT VARIABLES:
    ORADBA_TEST_IMAGE   Docker image to use (default: container-registry.oracle.com/database/free:latest)

EXAMPLES:
    # Run tests with default settings
    ./run_docker_tests.sh

    # Keep container running for manual inspection
    ./run_docker_tests.sh --keep-container

    # Use different image
    ./run_docker_tests.sh --image container-registry.oracle.com/database/free:23.6.0.0

EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

cleanup() {
    if [[ "$KEEP_CONTAINER" == "false" ]]; then
        log_info "Cleaning up container: $CONTAINER_NAME"
        docker rm -f "$CONTAINER_NAME" &> /dev/null || true
    else
        log_warn "Container kept running: $CONTAINER_NAME"
        log_info "Connect with: docker exec -it $CONTAINER_NAME bash"
        log_info "Stop with: docker stop $CONTAINER_NAME"
        log_info "Remove with: docker rm -f $CONTAINER_NAME"
    fi
}

wait_for_database() {
    local container="$1"
    local max_wait=180  # 3 minutes
    local elapsed=0
    
    log_info "Waiting for database to be ready (max ${max_wait}s)..."
    
    while [[ $elapsed -lt $max_wait ]]; do
        # SQL*Plus outputs with leading whitespace, so match flexible pattern
        if docker exec "$container" sh -c 'echo "SELECT 1 FROM DUAL;" | sqlplus -s / as sysdba' 2>&1 | grep -q -E "^\s+1$"; then
            log_success "Database is ready"
            return 0
        fi
        sleep 5
        ((elapsed+=5))
        echo -n "."
    done
    
    echo ""
    log_error "Database failed to start within ${max_wait}s"
    return 1
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
    log_info "OraDBA Docker Test Runner"
    echo ""
    
    # Build OraDBA if requested
    if [[ "$RUN_BUILD" == "true" ]]; then
        log_info "Building OraDBA distribution..."
        cd "$PROJECT_ROOT"
        if make build; then
            log_success "Build completed"
        else
            log_error "Build failed"
            exit 1
        fi
        echo ""
    fi
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check if image is available
    log_info "Checking Docker image: $DOCKER_IMAGE"
    if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
        log_warn "Image not found locally, pulling..."
        if docker pull "$DOCKER_IMAGE"; then
            log_success "Image pulled successfully"
        else
            log_error "Failed to pull image"
            exit 1
        fi
    fi
    echo ""
    
    # Start container
    log_info "Starting Oracle container: $CONTAINER_NAME"
    log_info "Image: $DOCKER_IMAGE"
    
    if docker run -d \
        --name "$CONTAINER_NAME" \
        -e ORACLE_PWD=Oracle123 \
        -v "$PROJECT_ROOT:/oradba:ro" \
        "$DOCKER_IMAGE" > /dev/null; then
        log_success "Container started: $CONTAINER_NAME"
    else
        log_error "Failed to start container"
        exit 1
    fi
    
    # Setup cleanup trap
    trap cleanup EXIT
    
    echo ""
    
    # Wait for database
    if ! wait_for_database "$CONTAINER_NAME"; then
        log_error "Database startup failed"
        docker logs "$CONTAINER_NAME" | tail -50
        exit 1
    fi
    
    echo ""
    log_info "Running automated tests..."
    echo ""
    echo "================================================================================"
    
    # Copy test script to container and run
    if docker exec "$CONTAINER_NAME" bash -c "
        chmod +x /oradba/tests/docker_automated_tests.sh && \
        /oradba/tests/docker_automated_tests.sh
    "; then
        echo "================================================================================"
        echo ""
        log_success "Tests completed successfully"
        
        # Copy results file
        local results_file
        results_file="/tmp/oradba_test_results_$(date +%Y%m%d_%H%M%S).log"
        docker exec "$CONTAINER_NAME" sh -c "cat /tmp/oradba_test_results_*.log" > "$results_file" 2>/dev/null || true
        
        if [[ -f "$results_file" ]]; then
            log_info "Test results saved to: $results_file"
        fi
        
        exit 0
    else
        echo "================================================================================"
        echo ""
        log_error "Tests failed"
        
        # Try to copy results even on failure
        local results_file
        results_file="/tmp/oradba_test_results_failed_$(date +%Y%m%d_%H%M%S).log"
        docker exec "$CONTAINER_NAME" sh -c "cat /tmp/oradba_test_results_*.log" > "$results_file" 2>/dev/null || true
        
        if [[ -f "$results_file" ]]; then
            log_info "Test results saved to: $results_file"
        fi
        
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-container)
            KEEP_CONTAINER=true
            shift
            ;;
        --no-build)
            RUN_BUILD=false
            shift
            ;;
        --image)
            DOCKER_IMAGE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main
main
