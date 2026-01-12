#!/usr/bin/env bats

load 'test_helper/common-setup'

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    source "$PROJECT_ROOT/compliment"
    _common_setup
}

@test "--chsh without argument shows error" {
    run "$PROJECT_ROOT/compliment" --chsh
    
    [ "$status" -eq 1 ]
    [ "${lines[-1]}" = "Error: Argument for --chsh is missing" ]
}

@test "--chsh changes shell type and updates logs" {
    # Create a mock completion file
    echo "#compdef mock" > "$BATS_TMPDIR/mock_completion"
    
    # Run compliment with --chsh zsh and --file
    run "$PROJECT_ROOT/compliment" --chsh zsh --file "$BATS_TMPDIR/mock_completion"
    
    [ "$status" -eq 0 ]
    
    # Check that the output contains "Shell type changed to: zsh"
    [[ "${lines[*]}" = *"Shell type changed to: zsh"* ]]
}

@test "--chsh works with different shell types" {
    # Create a mock completion file
    echo "#compdef mock" > "$BATS_TMPDIR/mock_completion"
    
    # Test with bash
    run "$PROJECT_ROOT/compliment" --chsh bash --file "$BATS_TMPDIR/mock_completion"
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" = *"Shell type changed to: bash"* ]]
    
    # Test with zsh
    run "$PROJECT_ROOT/compliment" --chsh zsh --file "$BATS_TMPDIR/mock_completion"
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" = *"Shell type changed to: zsh"* ]]
    
    # Test with fish (even if not fully supported)
    run "$PROJECT_ROOT/compliment" --chsh fish --file "$BATS_TMPDIR/mock_completion"
    [ "$status" -eq 0 ]
    [[ "${lines[*]}" = *"Shell type changed to: fish"* ]]
}

@test "--chsh affects --status command" {
    # Run with --chsh and --status
    run "$PROJECT_ROOT/compliment" --chsh zsh --status
    
    [ "$status" -eq 0 ]
    
    # The status output should mention zsh in the Active Shell line
    # Check if the output contains "Active Shell:" and "zsh"
    [[ "${output}" = *"Active Shell:"* ]] && [[ "${output}" = *"zsh"* ]]
}