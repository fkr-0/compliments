#!/usr/bin/env bats

load 'test_helper/common-setup'

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    source "$PROJECT_ROOT/compliment"
    _common_setup
}




completion_path() {
echo "$$(mktemp -d)/compicomp"
}

completion_stub() {
echo "#compdef test"
}

@test "can run our script" {
run ./compliment
assert_failure
assert_output --partial "compliment - a tool for managing shell completions"

}


@test "multiple_ensure_completion_loaded adds the autoload command to a zsh file" {
    local test_file=$(mktemp)
    # Create empty zsh file first
    touch "$test_file"
    
    # Create a temporary directory for completions
    local test_dir=$(mktemp -d)
    export ZSH_COMPLETION_DIR="$test_dir/zsh_completion"
    
    ensure_completion_loaded "zsh" "$test_file"
    ensure_completion_loaded "zsh" "$test_file"
    ensure_completion_loaded "zsh" "$test_file"
    ensure_completion_loaded "zsh" "$test_file"
    
    # Check that the autoload command is present
    grep -qF "fpath=($ZSH_COMPLETION_DIR" "$test_file"
    
    # Clean up
    rm -rf "$test_dir"
}

# # Test add_completion_from_file function
# @test "add_completion_from_file adds a completion file to the zsh completion directory" {
# add_completion_from_file "/path/to/completion/file" "test_completion" "zsh"
# [ -f "$ZSH_COMPLETION_DIR/test_completion" ]
# }

# @test "add_completion_from_file adds a completion file to the bash completion directory" {
# add_completion_from_file "/path/to/completion/file" "test_completion" "bash"
# [ -f "$BASH_COMPLETION_DIR/test_completion" ]
# }

# # Test remove_completion function
# @test "remove_completion removes a completion file from the zsh completion directory" {
# touch "$ZSH_COMPLETION_DIR/test_completion"
# remove_completion "test_completion" "zsh"
# [ ! -f "$ZSH_COMPLETION_DIR/test_completion" ]
# }

# @test "remove_completion removes a completion file from the bash completion directory" {
# touch "$BASH_COMPLETION_DIR/test_completion"
# remove_completion "test_completion" "bash"
# [ ! -f "$BASH_COMPLETION_DIR/test_completion" ]
# }

# # Test list_completions function
# @test "list_completions lists all completion files in the zsh completion directory" {
# touch "$ZSH_COMPLETION_DIR/test_completion"
# touch "$ZSH_COMPLETION_DIR/another_completion"
# list_completions "zsh" | grep -q "test_completion"
# list_completions "zsh" | grep -q "another_completion"
# }

# @test "list_completions lists all completion files in the bash completion directory" {
# touch "$BASH_COMPLETION_DIR/test_completion"
# touch "$BASH_COMPLETION_DIR/another_completion"
# list_completions "bash" | grep -q "test_completion"
# list_completions "bash" | grep -q "another_completion"
# }

# # Test ensure_completion_loaded function
# @test "ensure_completion_loaded adds the autoload command to a zsh file" {
# local test_file=$(mktemp)
# ensure_completion_loaded "zsh" "$test_file"
# grep -qF "compinit" "$test_file"
# }

# @test "ensure_completion_loaded adds the autoload command to a bash file" {
# local test_file=$(mktemp)
# ensure_completion_loaded "bash" "$test_file"
# grep -qF "bash_completion" "$test_file"
# }
