if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grepp="grep -Hn"

alias cpv='rsync -ah --info=progress2'
alias reload='echo "Reloading shell...";exec env -i HOME=$HOME bash -l'

# Git
alias gcl="(git branch --merged > /tmp/merged-branches && vi /tmp/merged-branches && xargs git branch -D < /tmp/merged-branches); git remote prune origin; git gc"
alias g='git'
alias gx='git update-index --add --chmod=+x'
alias squash-br='git reset $(git merge-base master $(git rev-parse --abbrev-ref HEAD)) && git add .'
alias wip='git add . && git ci -m WIP'
alias amend='git ci --amend --no-edit'

# Auto-cleanup branches merged into upstream/master
git-cleanup() {
  git fetch --all
  echo "=== Merged into upstream/master ==="
  git branch --merged upstream/master | grep -vE '^\*|\s*(master|main|v[0-9])' | sed 's/^/  /'
  echo "=== Gone upstream ==="
  git branch -vv | grep ': gone]' | awk '{print "  " $1}'
  echo "---"
  echo "Run: git-cleanup-do  to delete them"
}

git-cleanup-do() {
  git fetch --all
  local merged gone
  merged=$(git branch --merged upstream/master | grep -vE '^\*|\s*(master|main|v[0-9])')
  gone=$(git branch -vv | grep ': gone]' | awk '{print $1}')
  if [ -n "$merged" ]; then
    echo "$merged" | xargs git branch -d
  fi
  if [ -n "$gone" ]; then
    echo "$gone" | xargs git branch -D
  fi
  [ -z "$merged" ] && [ -z "$gone" ] && echo "Nothing to clean up."
}
