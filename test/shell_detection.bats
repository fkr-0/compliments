#!/usr/bin/env bats

load 'test_helper/common-setup'

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    source "$PROJECT_ROOT/compliment"
    _common_setup
}

@test "get_shell_type detects bash when running in bash" {
    # Test that the function detects bash correctly when BASH variable is set
    run bash -c "source $PROJECT_ROOT/compliment && get_shell_type"
    
    [ "$status" -eq 0 ]
    [ "$output" = "bash" ]
}

@test "get_shell_type detects zsh when running in zsh" {
    # Only run if zsh is available
    if command -v zsh >/dev/null 2>&1; then
        run zsh -c "source $PROJECT_ROOT/compliment && get_shell_type"
        
        [ "$status" -eq 0 ]
        [ "$output" = "zsh" ]
    else
        skip "zsh not available"
    fi
}

@test "get_shell_type falls back to /etc/passwd when not in interactive shell" {
    # Test that the function falls back to reading /etc/passwd
    # We can't easily mock /etc/passwd, but we can test that it returns something
    run bash -c "unset BASH && source $PROJECT_ROOT/compliment && get_shell_type"
    
    [ "$status" -eq 0 ]
    # Should return either bash or zsh (or whatever is in /etc/passwd)
    [[ "$output" =~ ^(bash|zsh|sh|fish|csh|tcsh|ksh)$ ]]
}

@test "get_shell_type uses cached _SHELL_TYPE when set" {
    # Test that the function returns the cached value when _SHELL_TYPE is set
    run bash -c "_SHELL_TYPE='testshell' && source $PROJECT_ROOT/compliment && get_shell_type"
    
    [ "$status" -eq 0 ]
    [ "$output" = "testshell" ]
}

@test "get_shell_type defaults to bash when /etc/passwd read fails" {
    # Mock grep to fail
    run bash -c "unset BASH && grep() { return 1; } && source $PROJECT_ROOT/compliment && get_shell_type"
    
    [ "$status" -eq 0 ]
    [ "$output" = "bash" ]
}