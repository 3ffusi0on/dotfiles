#!/usr/bin/env zx

import { spawnSync } from 'node:child_process'

$.verbose = true

const defaultBranch = argv._[0] || 'master' // rebase main

const nbOfCommits = await $`git rev-list --count HEAD ^${defaultBranch}`

spawnSync('git', ['rebase', '-i', `HEAD~${nbOfCommits.stdout.trim()}`], {
  stdio: 'inherit',
  shell: false,
})
