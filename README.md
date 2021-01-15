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

To demonstrate using `git-bisect` with an automated test, the `test.sh` script will evaluate our test case by attempting to `stat` the `i-must-exist.txt` file.  The script will exit with a status of `0` on success or `1` on failure, emulating how a test runner program might emit success/failure status during a test run (e.g. running `npm test` or `mvn test`);

### Generating commits
Since `git-bisect` is all about searching commits, we'll want a lot of commits to show off how effectively we can search the repository and quickly identify the 'bad' commit.

## The Demo

### Setup
Before we start, we'll sanity check our repository and confirm our tests are in fact passing:
```
$ ./test.sh
Test PASSED
```

To get the commits we need to demonstrate `git-bisect`, we'll run `generate-commits.sh` to create a branch and make commits to it:
```
$ ./generate-commits.sh
```
This will generate 100 commits in our repository, with the 'bad' commit (that removes `i-must-exist.txt`) hidden somewhere in thaat range.

Now, we can run `test.sh`, and we should see our repository is in a broken state:
```
$ ./test.sh
Test FAILED
```

### Finding the 'bad' commit (The good stuff)
First, we'll start `git-bisect`:

```
$ git bisect start
```

Next, we'll feed it a 'good' commit as a start point.  We can use the commit from the output of `generate-commits.sh`, or, for simplicity, the `HEAD` of `master` (master is the starting point of our demo branch):

```
$ git bisect good master
```

Since we know that the `HEAD` of our current branch is broken, we'll use that as our initial 'bad' commit:
```
$ git bisect bad HEAD
```


At this point, `git-bisect` will test us how many revisions we have left to sort through, and how many iterations it expects to take to find our original 'bad' commit.  The output will look something like this:
```
Bisecting: 49 revisions left to test after this (roughly 6 steps)
[08abfb9e7b0ba8960470eb92355ccf8fd94c81e0] Added random-file-0f347d5b99a5c858f94f72133109990e.txt
```

Now, our bisect operation is still pointed at the `HEAD` of our branch, so we'll tell `git-bisect` that and move to the next commit:

```
$ git bisect bad
```

This will cause our bisect operation to find the halfway point in the tree between the revision we've specified as 'good' (`HEAD` of `master`) and 'bad' (`HEAD` of our demo branch).  At this point, we'll run our test again to see if this is a 'good' commit or a 'bad' one:

```
$ ./test.sh
# Outputs 'Test PASSED' or 'Test FAILED'
# If we passed:
$ git bisect good
# If we failed:
$ git bisect bad
```

We'll repeat this process until `git-bisect` has assessed enough commits to identify the 'bad commit'.  It will look something like this:
```
$ git bisect good
d8668c18cdcd47ca7d2a316a449658658b3c3e62 is the first bad commit
commit d8668c18cdcd47ca7d2a316a449658658b3c3e62
Author: Kevin Ziegler <ziegler.kevin@heb.com>
Date:   Fri Jan 15 12:37:46 2021 -0600

    Removed i-must-exist.txt.txt

 i-must-exist.txt | 5 -----
 1 file changed, 5 deletions(-)
 delete mode 100644 i-must-exist.txt
```

We've now identified the offending commit, and can figure out how to take action to fix it.  But, we found that one bad commit in a hundred different ones with just a few steps!

To finish up, we'll exit the `git-bisect` operation:

```
$ git bisect reset
```

#### It Gets Better
`git-bisect` already saved us a lot of effort elminating commits we might have to search, but now we can do one better and automate the testing process.  Our `test.sh` script exits with a status of `0` on success and `1` on failure, emulating the behavior of testing tools in many languages.  Because of this, we can tell `git-bisect` to run `test.sh` on every iteration and decide if a commit is 'good' or 'bad' for itself!

We'll reset our example and go again:
```
$ git checkout master
$ ./generate-commits.sh
$ git bisect start
$ git bisect good master
$ git bisect bad HEAD
```

At this point we've:
* Generated a new branch and hidden a bad commit in it
* Initialized `git-bisect`
* Informed the bisect operation of our initial good/bad commits

Now, to automate finding the bad commit, we simply tell `git-bisect` to run our test script on every commit it visits to determine if it's good or bad:
```
$ git bisect run ./test.sh
```

And, like magic, `git-bisect` will again tell us the bad commit:

```
bc2334ec41317c33f4adf863e09caac6b59c9840 is the first bad commit
commit bc2334ec41317c33f4adf863e09caac6b59c9840
Author: Kevin Ziegler <ziegler.kevin@heb.com>
Date:   Fri Jan 15 13:03:33 2021 -0600

    Removed i-must-exist.txt.txt

 i-must-exist.txt | 5 -----
 1 file changed, 5 deletions(-)
 delete mode 100644 i-must-exist.txt
bisect run success
```

