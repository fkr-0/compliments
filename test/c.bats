#!/usr/bin/env bats

# load 'test_helper.bash'
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    # ... the remaining setup is unchanged
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/..:$PATH"
    # Create temporary completion directories for testing
    export BASH_COMPLETION_DIR="$(mktemp -d)"
    export ZSH_COMPLETION_DIR="$(mktemp -d)"
    export HOME="$(mktemp -d)"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME"
    # export compliment="$DIR/../compliment"
}
# compliment()


teardown() {
    # Clean up after tests
    rm -rf "$BASH_COMPLETION_DIR"
    rm -rf "$ZSH_COMPLETION_DIR"
    rm -rf "$HOME"
}

@test "Add completion from file" {
    local test_file="$(mktemp)"
    echo "test" > "$test_file"

    run bash compliment --file "$test_file"
    [ "$status" -eq 0 ]
    [ -f "$ZSH_COMPLETION_DIR/$(basename "$test_file")" ]
}

@test "Add completion from command" {
    local cmd="echo hello"
    local name="test_completion.sh"

    run bash compliment --command "$cmd" "$name"
    [ "$status" -eq 0 ]
    [ -f "$ZSH_COMPLETION_DIR/$name" ]
    [ "$(cat "$ZSH_COMPLETION_DIR/$name")" = "hello" ]
}

@test "Remove completion" {
    local name="test_completion.sh"
    echo "test" > "$ZSH_COMPLETION_DIR/$name"

    run bash compliment --remove "$name"
    [ "$status" -eq 0 ]
    [ ! -f "$ZSH_COMPLETION_DIR/$name" ]
}

@test "List completions" {
    local name1="completion1.sh"
    local name2="completion2.sh"
    echo "test" > "$ZSH_COMPLETION_DIR/$name1"
    echo "test" > "$ZSH_COMPLETION_DIR/$name2"

    run bash compliment --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"$name1"* ]]
    [[ "$output" == *"$name2"* ]]
}

# Add more tests as needed...
