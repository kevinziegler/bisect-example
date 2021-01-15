#!/usr/bin/env bash
set -euo pipefail

# These variables can be tweaked to make the breaking commit more or less
# visible.

# NUM_COMMITS [Default: 100]
# Number of commits to generate in the repository over the course of running
# this script.
NUM_COMMITS="${NUM_COMMITS:-100}";

# BAD_COMMIT_PADDING [Default: 10]
# This indicates the number of "noise" commits (that will not induce failure)
# that must be genertated at the start and end of the script run, to help
# avoid creating a completely trivial example
BAD_COMMIT_PADDING="${BAD_COMMIT_PADDING:-10}";

# HARD_MODE [Default: 0]
# If set to 0, commit messages will indicate either that a file was added, or
# that the file was removed.  This makes it easier to identify the breaking
# commit by inspecting the git log.
#
# If set to 1, all commit messages will be the same, hiding the 'bad' commit
# so that it is not readily visible in the git log.
HARD_MODE="${HARD_MODE:-0}";

# SHOW_BAD_COMMIT [Default: 0]
# If set to 1, the 'bad' commit will be printed out during script execution
SHOW_BAD_COMMIT="${SHOW_BAD_COMMIT:-0}";

DEMO_BRANCH_START="bisect-demo-start";
I_MUST_EXIST="i-must-exist.txt";
HARD_COMMIT_MESSAGE="Make changes [I suck and I want my coworkers to suffer]";

# Compute values for hiding the 'bad' commit in the repository.  To make sure
# we don't place the 'bad' commit at the very start or the very end of history,
# we pad the range of NUM_COMMITS by BAD_COMMIT_PADDING commits that will be
# guaranteed to be 'good'.
BAD_COMMIT_MAX=$(( $NUM_COMMITS - $BAD_COMMIT_PADDING ));
BAD_COMMIT_MIN=$(( $BAD_COMMIT_PADDING + 1 ));
BAD_COMMIT=$(shuf -i $BAD_COMMIT_MIN-$BAD_COMMIT_MAX -n 1);

# Helper function to generate random bytes of data for creating random files,
# as well as the branch name we'll need for this repository.
function random_string() {
    local length=${1:-32};
    cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c "$length";
}

# Create a random file and commit it to the repository.  These will be 'good'
# commits that do not break the repository (but may reflect a broken repository)
# state if they occur after the breaking commit.
function generate_noise_commit() {
    local noise=$(random_string);
    local noise_file="random-file-$noise.txt";

    echo "$noise" > "$noise_file";
    git add "$noise_file";

    if [ "$HARD_MODE" == "1" ]; then
        git commit -q -m "$HARD_COMMIT_MESSAGE";
    else
        git commit -q -m "Added $noise_file";
    fi
}

# Generate a commit that deletes the file we need for our test script to pass.
function generate_breaking_commit() {
    git rm "$I_MUST_EXIST";

    if [ "$HARD_MODE" == "1" ]; then
        git commit -q -m "$HARD_COMMIT_MESSAGE";
    else
        git commit -q -m "Removed $I_MUST_EXIST.txt";
    fi

    if [ "$SHOW_BAD_COMMIT" == "1" ]; then
        echo "The breaking commit is $(git rev-parse HEAD)";
    fi
}

# Create a branch to run the demo in.  This allows us to keep 'master' clean.
if $(git rev-parse --verify --quiet "$BISECT_DEMO_START"); then
    git checkout -b "git-biset-demo-$(random_string)" "$BISECT_DEMO_START";
else
    echo "Invalid BISECT_DEMO_START; branching from HEAD";
    git checkout -b "git-biset-demo-$(random_string)";
fi

echo "Generating $NUM_COMMITS in the repository.";
echo "HARD_MODE is set to $HARD_MODE";

if [ "$SHOW_BAD_COMMIT" == "1" ]; then
    echo "The breaking commit will be commit #$BAD_COMMIT";
fi

# Generate NUM_COMMITS in the repository that we'll search with git-bisect to
# find the breaking commit in our demo.
for i in $(seq 1 $NUM_COMMITS); do
    if [ "$i" == "$BAD_COMMIT" ]; then
        generate_breaking_commit;
    else
        generate_noise_commit;
    fi

    if [ "$i" == "$BAD_COMMIT_PADDING" ]; then
        echo "Last guaranteed good commit is $(git rev-parse HEAD).  This can be used as the 'good' commit to start from. ";
    fi
done

echo "You now have a bug.  Happy hunting!";
