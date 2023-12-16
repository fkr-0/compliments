#!/usr/bin/env bats

# Load the main script for testing
load './compliment'

setup() {
    # Setup test environment
    TEST_DIR=$(mktemp -d)
    export BASH_COMPLETION_DIR="$TEST_DIR/bash_completion"
    export ZSH_COMPLETION_DIR="$TEST_DIR/zsh_completion"
    mkdir -p "$BASH_COMPLETION_DIR" "$ZSH_COMPLETION_DIR"
}

teardown() {
    # Clean up test environment
    rm -rf "$TEST_DIR"
}

@test "add_completion_from_file adds file to bash completion directory" {
    touch "$TEST_DIR/test_completion"
    add_completion_from_file "$TEST_DIR/test_completion" "bash"
    [ -f "$BASH_COMPLETION_DIR/test_completion" ]
}

@test "add_completion_from_file adds file to zsh completion directory" {
    touch "$TEST_DIR/test_completion"
    add_completion_from_file "$TEST_DIR/test_completion" "zsh"
    [ -f "$ZSH_COMPLETION_DIR/test_completion" ]
}

@test "add_completion_from_command adds command output to bash completion directory" {
    echo "echo test" > "$TEST_DIR/test_command"
    add_completion_from_command "bash $TEST_DIR/test_command" "test_completion" "bash"
    [ "$(cat "$BASH_COMPLETION_DIR/test_completion")" = "test" ]
}

@test "add_completion_from_command adds command output to zsh completion directory" {
    echo "echo test" > "$TEST_DIR/test_command"
    add_completion_from_command "bash $TEST_DIR/test_command" "test_completion" "zsh"
    [ "$(cat "$ZSH_COMPLETION_DIR/test_completion")" = "test" ]
}

@test "ensure_completion_loaded does not add the same code multiple times" {
    local zshrc="$TEST_DIR/.zshrc"
    touch "$zshrc"
    ensure_completion_loaded "zsh" "$zshrc"
    ensure_completion_loaded "zsh" "$zshrc" # Second call
    # Count the number of times the autoload command is present
    count=$(grep -c "fpath=($ZSH_COMPLETION_DIR \$fpath)" "$zshrc")
    [ "$count" -eq 1 ]
}

@test "ensure_completion_loaded inserts before the first autoload command" {
    local zshrc="$TEST_DIR/.zshrc"
    touch "$zshrc"
    echo "# stuff 1" >> "$zshrc"
    echo "# stuff 2" >> "$zshrc"
    echo "# stuff 3" >> "$zshrc"
    echo "autoload -U compinit; compinit; # stuuuuuff 4" >> "$zshrc"
    echo "# stuff 5" >> "$zshrc"
    echo "# stuff 6" >> "$zshrc"
    ensure_completion_loaded "zsh" "$zshrc"
    comp_dir_line_no="$(grep -nF "fpath=($ZSH_COMPLETION_DIR \$fpath)" "$zshrc" | cut -d: -f1)"
    autoload_line_no="$(grep -nF "autoload -U compinit; compinit" "$zshrc" | cut -d: -f1)"
    [ "$comp_dir_line_no" -eq "$((autoload_line_no - 1))" ]
    # get the line number of the insertion of comp dir
}

# compliment_tests.bats (continued)

@test "ensure_completion_loaded adds autoload command for zsh" {
    local zshrc="$TEST_DIR/.zshrc"
    touch "$zshrc"
    ensure_completion_loaded "zsh" "$zshrc"
    grep -qF "fpath=($ZSH_COMPLETION_DIR \$fpath)" "$zshrc"
}

@test "ensure_completion_loaded adds autoload command for bash" {
    local bashrc="$TEST_DIR/.bashrc"
    touch "$bashrc"
    ensure_completion_loaded "bash" "$bashrc"
    grep -qF "for file in $BASH_COMPLETION_DIR/*; do . \"\$file\"; done" "$bashrc"
}

@test "add and process zsh completion for test_cmd" {
    # Define a simple completion function for 'test_cmd'
    echo "#compdef test_cmd" > "$ZSH_COMPLETION_DIR/_test_cmd"
    echo "_test_cmd() { reply=(--help) }" >> "$ZSH_COMPLETION_DIR/_test_cmd"

    # Adjust fpath and initialize completions
    local zshrc="$TEST_DIR/.zshrc"
    echo "fpath=($ZSH_COMPLETION_DIR \$fpath)" > "$zshrc"
    echo "autoload -Uz compinit && compinit" >> "$zshrc"

    # Test the completion
    run zsh -f -c "source '$zshrc'; _test_cmd; echo \$reply"
    [ "$status" -eq 0 ]
    [ "$output" = "--help" ]
}
