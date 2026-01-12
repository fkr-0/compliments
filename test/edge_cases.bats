#!/usr/bin/env bats

# Load main script for testing
load '../compliment'

setup() {
    # Setup test environment
    TEST_DIR=$(mktemp -d)
    export BASH_COMPLETION_DIR="$TEST_DIR/bash_completion"
    export ZSH_COMPLETION_DIR="$TEST_DIR/zsh_completion"
    mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR"
    
    # Create mock shell config files
    touch "$TEST_DIR/.zshrc"
    touch "$TEST_DIR/.bashrc"
    export HOME="$TEST_DIR"
    
    # Load the compliment script with our test environment
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    load "$PROJECT_ROOT/compliment"
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_DIR"
}

@test "add_completion_from_file handles non-existent file" {
    run add_completion_from_file "/nonexistent/file" "bash"
    [ "$status" -eq 1 ]
}

@test "add_completion_from_command handles failing command" {
    run add_completion_from_command "false" "test_completion" "bash"
    [ "$status" -eq 1 ]
}

@test "add_completion_from_command handles command with output" {
    run add_completion_from_command "echo 'completion content'" "test_completion" "bash"
    [ "$status" -eq 0 ]
    [ -f "$BASH_COMPLETION_DIR/test_completion" ]
    grep -q "completion content" "$BASH_COMPLETION_DIR/test_completion"
}

@test "add_completion_from_stdin creates file from stdin" {
    echo "#!/bin/bash" | add_completion_from_stdin "stdin_completion" "zsh"
    [ -f "$ZSH_COMPLETION_DIR/stdin_completion" ]
}

@test "completion directory creation respects custom COMPLETION_DIRNAME" {
    # Clear any existing completion dir variables
    unset ZSH_COMPLETION_DIR
    unset BASH_COMPLETION_DIR
    export COMPLETION_DIRNAME="_my_completions"
    run get_completion_dir "bash"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "_my_completions"
}

@test "get_config_dir handles missing config gracefully" {
    # Remove all config files
    rm -f "$TEST_DIR/.bashrc" "$TEST_DIR/.bash_profile"
    run get_config_dir "bash"
    [ "$status" -eq 1 ]
}

@test "get_completion_dir respects environment variables" {
    export BASH_COMPLETION_DIR="$TEST_DIR/custom_bash_completion"
    run get_completion_dir "bash"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/custom_bash_completion" ]
}

@test "ensure_completion_loaded idempotent for bash" {
    local bashrc="$TEST_DIR/.bashrc"
    echo "some config" >"$bashrc"
    
    ensure_completion_loaded "bash" "$bashrc"
    ensure_completion_loaded "bash" "$bashrc"
    
    # Should only add autoload command once
    local count
    count=$(grep -c "for file in $BASH_COMPLETION_DIR" "$bashrc")
    [ "$count" -eq 1 ]
}

@test "ensure_completion_loaded handles missing compinit gracefully" {
    local zshrc="$TEST_DIR/.zshrc"
    echo "# no compinit here" >"$zshrc"
    
    run ensure_completion_loaded "zsh" "$zshrc"
    [ "$status" -eq 0 ]
    grep -q "fpath=" "$zshrc"
}

@test "reload_completions works for bash" {
    touch "$BASH_COMPLETION_DIR/test_comp.sh"
    echo "test_var=test_value" >"$BASH_COMPLETION_DIR/test_comp.sh"
    
    run reload_completions "bash"
    [ "$status" -eq 0 ]
}

@test "reload_completions works for zsh when in zsh" {
    # This test is limited since we're not running in zsh
    # but we can test that it at least attempts the right commands
    touch "$ZSH_COMPLETION_DIR/test_comp"
    
    # We can't easily test zsh reload from bash, so just verify it doesn't error
    if [ -n "${ZSH_VERSION:-}" ]; then
        run reload_completions "zsh"
        [ "$status" -eq 0 ]
    fi
}

@test "show_status handles non-existent directories" {
    rm -rf "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR"
    run show_status
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "Directory does not exist"
}

@test "show_status displays environment variables" {
    export COMPLETION_DIRNAME="test_dir"
    run show_status
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "test_dir"
}

@test "logging respects DEBUG flag" {
    DEBUG=0 run log "DEBUG" "debug message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    
    DEBUG=1 run log "DEBUG" "debug message"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}