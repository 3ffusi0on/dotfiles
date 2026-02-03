#!/usr/bin/env zx

$.verbose = true

const defaultBranch = argv._[0] || 'master' // rebase main

const nbOfCommits = await $`git rev-list --count HEAD ^${defaultBranch}`

await $`git rebase -i HEAD~${nbOfCommits}`