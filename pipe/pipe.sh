#!/usr/bin/env bash
#
set -e

source "$(dirname "$0")/common.sh"


DEBUG=${DEBUG:=false}
STANDARDS=${STANDARDS:="Security"}

echo "Testing modified files in this branch..."

TARGET_BRANCH='origin/master'
if [ -n "$BITBUCKET_PR_DESTINATION_BRANCH" ]; then
       TARGET_BRANCH="origin/$BITBUCKET_PR_DESTINATION_BRANCH"
fi

if $DEBUG; then
     echo "State of working directory"
     git status
fi

echo "Comparing HEAD against branch $TARGET_BRANCH"
MERGE_BASE=$(git merge-base HEAD $TARGET_BRANCH)

echo "Comparing HEAD against merge base $MERGE_BASE"
CHANGED_FILES=$(git diff --relative --name-only --diff-filter=AM $MERGE_BASE -- '*.php' '*.phtml')

if [ -z "$CHANGED_FILES" ]; then
  echo "No changed PHP files to scan"
else
  if $DEBUG; then
    echo "Changed files: "
    echo $CHANGED_FILES
  fi
  mkdir -p test-results
  ./vendor/bin/phpcs --report=junit \
     --standard=${STANDARDS},Security $CHANGED_FILES > test-results/phpcs.xml || ./vendor/bin/phpcs --standard=${STANDARDS},Security $CHANGED_FILES && echo "No violations found"
fi

if [[ "$?" == "0" ]]; then
  success "Success!"
else
  fail "Error!"
fi
