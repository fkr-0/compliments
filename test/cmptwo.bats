#!/usr/bin/env bats

# setup() {
# # get the containing directory of this file
# # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
# # as those will point to the bats executable's location or the preprocessed file respectively
# DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
# # make executables in src/ visible to PATH
# PATH="$DIR/..:$PATH"
# echo "$(pwd)"
# source "$(pwd)/compliment"
# export ZSH_COMPLETION_DIR=$(mktemp -d)
# export BASH_COMPLETION_DIR=$(mktemp -d)
# }
setup() {
    load 'test_helper/common-setup'
    source "$(pwd)/compliment"
    _common_setup
    
    # Create temporary completion directories
    export ZSH_COMPLETION_DIR=$(mktemp -d)
    export BASH_COMPLETION_DIR=$(mktemp -d)
}

teardown() {
    # Clean up temporary directories
    rm -rf "$ZSH_COMPLETION_DIR" 2>/dev/null || true
    rm -rf "$BASH_COMPLETION_DIR" 2>/dev/null || true
}


completion_path() {
echo "$$(mktemp -d)/compicomp"
}

completion_stub() {
echo "#compdef test"
}

@test "can run our script" {
run bash compliment
assert_output --partial "Usage: compliment"

}


#Test multiple_ensure_completion_loaded function
@test "multiple_ensure_completion_loaded adds the autoload command to a zsh file" {
    local test_file=$(mktemp)
    ensure_completion_loaded "zsh" "$test_file"
    ensure_completion_loaded "zsh"
    ensure_completion_loaded "zsh"
    ensure_completion_loaded "zsh"
    # Check that there's exactly one "compinit" line in the test file
    local count=$(grep -c "compinit" "$test_file")
    [ "$count" -eq 1 ]
}

@test "List completions" {
local name1="completion1.sh"
local name2="completion2.sh"
echo "test" > "$BASH_COMPLETION_DIR/$name1"
echo "test" > "$BASH_COMPLETION_DIR/$name2"
run bash ./compliment --list
assert_output --partial "completion1.sh"
# run bash compliment --list
# [ "$status" -eq 0 ]
# [[ "$output" == *"$name1"* ]]
# [[ "$output" == *"$name2"* ]]
}
# Test add_completion_from_file function
@test "add_completion_from_file adds a completion file to the zsh completion directory" {
    echo "# Test completion" > /tmp/test_completion
    add_completion_from_file "/tmp/test_completion" "test_completion" "zsh"
    [ -f "$ZSH_COMPLETION_DIR/test_completion" ]
}

@test "add_completion_from_file adds a completion file to the bash completion directory" {
    echo "# Test completion" > /tmp/test_completion
    add_completion_from_file "/tmp/test_completion" "test_completion" "bash"
    [ -f "$BASH_COMPLETION_DIR/test_completion" ]
}

# Test remove_completion function
@test "remove_completion removes a completion file from the zsh completion directory" {
    touch "$ZSH_COMPLETION_DIR/test_completion"
    remove_completion "test_completion" "zsh"
    [ ! -f "$ZSH_COMPLETION_DIR/test_completion" ]
}

@test "remove_completion removes a completion file from the bash completion directory" {
    touch "$BASH_COMPLETION_DIR/test_completion"
    remove_completion "test_completion" "bash"
    [ ! -f "$BASH_COMPLETION_DIR/test_completion" ]
}

# Test list_completions function
@test "list_completions lists all completion files in the zsh completion directory" {
    touch "$ZSH_COMPLETION_DIR/test_completion"
    touch "$ZSH_COMPLETION_DIR/another_completion"
    run list_completions "zsh"
    echo "$output" | grep -q "test_completion"
    echo "$output" | grep -q "another_completion"
}

@test "list_completions lists all completion files in the bash completion directory" {
    touch "$BASH_COMPLETION_DIR/test_completion"
    touch "$BASH_COMPLETION_DIR/another_completion"
    run list_completions "bash"
    echo "$output" | grep -q "test_completion"
    echo "$output" | grep -q "another_completion"
}

# Test ensure_completion_loaded function
@test "ensure_completion_loaded adds the autoload command to a zsh file" {
    local test_file=$(mktemp)
    ensure_completion_loaded "zsh" "$test_file"
    grep -qF "compinit" "$test_file"
}

@test "ensure_completion_loaded adds the autoload command to a bash file" {
local test_file=$(mktemp)
ensure_completion_loaded "bash" "$test_file"
grep -qF "bash_completion" "$test_file"
}
