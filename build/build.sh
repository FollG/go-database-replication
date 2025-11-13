#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project variables
PROJECT_NAME="mysql-replication-app"
VERSION=${1:-"1.0.0"}
BUILD_DIR="./bin"
DOCKER_IMAGE="${PROJECT_NAME}:${VERSION}"
PLATFORMS=("linux/amd64" "linux/arm64")

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [VERSION] [COMMAND]

Commands:
    build       Build the application (default)
    test        Run tests
    docker      Build Docker image
    clean       Clean build artifacts
    all         Build, test and create Docker image
    help        Show this help message

Examples:
    $0 1.0.0 build
    $0 1.0.0 all
    $0 test
    $0 docker
EOF
}

# Check if Go is installed
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed or not in PATH"
        exit 1
    fi
    log_info "Go version: $(go version)"
}

# Clean build artifacts
clean() {
    log_info "Cleaning build artifacts..."
    rm -rf ${BUILD_DIR}
    rm -f coverage.html coverage.out
    docker system prune -f 2>/dev/null || true
    log_info "Clean completed"
}

# Run tests
run_tests() {
    log_info "Running tests..."

    # Create test coverage directory
    mkdir -p ${BUILD_DIR}

    # Run tests with coverage
    if go test -v -race -coverprofile=coverage.out -covermode=atomic ./...; then
        log_info "Tests passed successfully"

        # Generate HTML coverage report
        go tool cover -html=coverage.out -o coverage.html
        log_info "Coverage report generated: coverage.html"

        # Show coverage summary
        go tool cover -func=coverage.out | tail -1
    else
        log_error "Tests failed"
        exit 1
    fi
}

# Build the application
build_app() {
    log_info "Building application version: ${VERSION}"

    # Create build directory
    mkdir -p ${BUILD_DIR}

    # Set Go modules on
    export GO111MODULE=on

    # Build for current platform
    log_info "Building for current platform..."
    go build -ldflags="-X main.version=${VERSION} -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
             -o ${BUILD_DIR}/${PROJECT_NAME} ./cmd/app

    if [ $? -eq 0 ]; then
        log_info "Build successful: ${BUILD_DIR}/${PROJECT_NAME}"
        ${BUILD_DIR}/${PROJECT_NAME} -version
    else
        log_error "Build failed"
        exit 1
    fi
}

# Build for multiple platforms
build_multi_platform() {
    log_info "Building for multiple platforms..."

    for platform in "${PLATFORMS[@]}"; do
        os=$(echo ${platform} | cut -d'/' -f1)
        arch=$(echo ${platform} | cut -d'/' -f2)
        output_name="${BUILD_DIR}/${PROJECT_NAME}-${os}-${arch}"

        if [ "$os" = "windows" ]; then
            output_name+='.exe'
        fi

        log_info "Building for ${os}/${arch}..."
        GOOS=$os GOARCH=$arch go build \
            -ldflags="-X main.version=${VERSION} -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            -o ${output_name} ./cmd/app
    done

    log_info "Multi-platform build completed"
    ls -la ${BUILD_DIR}/
}

# Build Docker image
build_docker() {
    log_info "Building Docker image: ${DOCKER_IMAGE}"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Build the image
    docker build -t ${DOCKER_IMAGE} -f Dockerfile ..

    if [ $? -eq 0 ]; then
        log_info "Docker image built successfully: ${DOCKER_IMAGE}"

        # Show image info
        docker images | grep ${PROJECT_NAME}
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Run security checks
security_checks() {
    log_info "Running security checks..."

    # Check if gosec is installed
    if command -v gosec &> /dev/null; then
        log_info "Running gosec security scanner..."
        gosec ./...
    else
        log_warn "gosec not installed, skipping security scan"
        log_warn "Install with: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"
    fi

    # Check for vulnerabilities in dependencies
    log_info "Checking for dependency vulnerabilities..."
    go mod tidy
    go list -json -m all | go mod why -m -all
}

# Main execution
main() {
    local command=${2:-"build"}

    case $command in
        "build")
            check_go
            build_app
            ;;
        "build-multi")
            check_go
            build_multi_platform
            ;;
        "test")
            check_go
            run_tests
            ;;
        "docker")
            check_go
            build_docker
            ;;
        "security")
            check_go
            security_checks
            ;;
        "clean")
            clean
            ;;
        "all")
            check_go
            clean
            run_tests
            security_checks
            build_app
            build_docker
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Create bin directory if it doesn't exist
mkdir -p ${BUILD_DIR}

# Run main function with all arguments
main "$@"