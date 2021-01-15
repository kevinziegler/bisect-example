# Git Bisect Example repository
This repository provides an interactive example for using `git-bisect` to identify the specific commit that introduced a regression into a repository.

## How this example works
To demonstrate git-bisect, we need a few things:
* A test case to determine if a commit is "good" (working) or "bad" (broken)
* A git repository with a history of changes (including a "breaking" change)
* [Optional] A test script/program to run our test case automatically

### The Test Case
To keep the context of our example simple (so that we can instead focus) on the mechanics of `git-bisect`, our test case will be as follows:
> The file 'i-must-exist.txt' must exist in the repository's root directory

So long as this condition is satisfied for a commit, our tests for the repository should pass.  This is reflected in the initial state of the repository where we'll start our example.  Additionally, it will be the condition checked by the `test.sh` script in this repository.

