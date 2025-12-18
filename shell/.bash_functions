# git post-push hook call
git() {
  ROOT="$(/usr/bin/git rev-parse --show-toplevel)"
  LOCATION="/.git/hooks/post-push"
  if [ "$1" == "push" ] && [ -f "$ROOT$LOCATION" ]; then
    /usr/bin/git $* && eval $ROOT$LOCATION
  else
    /usr/bin/git $*
  fi
}

# fixup past commit
fixup () {
  if [ -n "$(git status --porcelain)" ]; then
    git commit --fixup $1 && git stash && git rebase --autosquash $1~ && git stash pop;
  else
    git commit --fixup $1 && git rebase --autosquash $1~;
  fi
}

# Move a commit (default HEAD) to a new branch
gtb() {
    if [ -z "$1" ]; then
        echo "Usage: gtb <new-branch-name> [commit-ref]"
        return 1
    fi

    local NEW_BRANCH=$1
    local COMMIT_REF=${2:-"HEAD"} # Defaults to HEAD if $2 is empty

    # 1. Create the new branch at the specified commit
    git branch "$NEW_BRANCH" "$COMMIT_REF"
    
    # 2. If we moved a specific commit that isn't HEAD, 
    # we usually need to remove it from the current history via rebase.
    # If it IS HEAD, we just reset.
    if [ "$COMMIT_REF" = "HEAD" ]; then
        git reset --soft HEAD~1
        echo "Moved HEAD to '$NEW_BRANCH'. Current branch reset --soft."
    else
        echo "Branch '$NEW_BRANCH' created at $COMMIT_REF."
        echo "Note: To remove $COMMIT_REF from this branch, use: git rebase --onto $COMMIT_REF^ $COMMIT_REF"
    fi
}
