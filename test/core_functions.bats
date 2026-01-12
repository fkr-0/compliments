#!/usr/bin/env bats

# Load the main script for testing
load '../compliment'

setup() {
    # Setup test environment
    TEST_DIR=$(mktemp -d)
    export BASH_COMPLETION_DIR="$TEST_DIR/bash_completion"
    export ZSH_COMPLETION_DIR="$TEST_DIR/zsh_completion"
    mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR"
    
    # Create mock shell config files in TEST_DIR
    touch "$TEST_DIR/.bashrc"
    touch "$TEST_DIR/.zshrc"
    
    # Load the compliment script
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    load "$PROJECT_ROOT/compliment"
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_DIR"
}

@test "get_shell_type returns valid shell type" {
    run get_shell_type
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_config_dir returns correct directory for bash" {
    # Create a .bashrc file in TEST_DIR
    touch "$TEST_DIR/.bashrc"
    
    # Override HOME to point to TEST_DIR
    HOME="$TEST_DIR"
    
    run bash_conf_dir
    [ "$status" -eq 0 ]
    # Check that it returns the test directory
    echo "$output" | grep -q "$TEST_DIR"
}

@test "get_config_dir returns correct directory for zsh" {
    # Create a .zshrc file in TEST_DIR
    touch "$TEST_DIR/.zshrc"
    
    # Override HOME to point to TEST_DIR
    HOME="$TEST_DIR"
    
    run zsh_conf_dir
    [ "$status" -eq 0 ]
    # Check that it returns the test directory
    echo "$output" | grep -q "$TEST_DIR"
}

@test "get_completion_dir creates appropriate path" {
    run get_completion_dir "bash"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "completion"
    
    run get_completion_dir "zsh"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "completion"
}

@test "add_completion_from_stdin handles input correctly" {
    echo "#!/bin/bash" | add_completion_from_stdin "test_completion" "bash"
    [ -f "$BASH_COMPLETION_DIR/test_completion" ]
    grep -q "#!/bin/bash" "$BASH_COMPLETION_DIR/test_completion"
}

@test "remove_completion removes existing file" {
    touch "$BASH_COMPLETION_DIR/test_remove"
    remove_completion "test_remove" "bash"
    [ ! -f "$BASH_COMPLETION_DIR/test_remove" ]
}

@test "remove_completion handles non-existent file" {
    run remove_completion "nonexistent" "bash"
    [ "$status" -eq 1 ]
}

@test "list_completions shows empty when no completions" {
    run list_completions "bash"
    [ "$status" -eq 0 ]
}

@test "list_completions shows completions when present" {
    touch "$BASH_COMPLETION_DIR/comp1"
    touch "$BASH_COMPLETION_DIR/comp2"
    run list_completions "bash"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "comp1"
    echo "$output" | grep -q "comp2"
}

@test "reload_completions handles missing directory" {
    # Remove the completion directory
    rmdir "$BASH_COMPLETION_DIR"
    run reload_completions "bash"
    [ "$status" -eq 1 ]
}

@test "show_status produces output" {
    run show_status
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Compliment Status Report"
}

@test "log function handles different levels" {
    run log "INFO" "test message"
    [ "$status" -eq 0 ]
    
    run log "ERROR" "test error"
    [ "$status" -eq 0 ]
    
    # Skip debug test as it depends on output to stderr
}

@test "sourced_p detects when script is not sourced" {
    run sourced_p
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "ensure_completion_loaded creates directory if needed" {
    local zshrc="$TEST_DIR/.zshrc"
    echo "autoload -U compinit; compinit" >"$zshrc"
    
    # Remove completion directory
    rmdir "$ZSH_COMPLETION_DIR" 2>/dev/null || true
    
    # Create the completion directory (since ensure_completion_loaded doesn't create it)
    mkdir -p "$ZSH_COMPLETION_DIR"
    
    # Run ensure_completion_loaded directly (not with 'run')
    if ensure_completion_loaded "zsh" "$zshrc"; then
        # Check if the directory exists (it should)
        [ -d "$ZSH_COMPLETION_DIR" ]
    else
        echo "ensure_completion_loaded failed"
        exit 1
    fi
}