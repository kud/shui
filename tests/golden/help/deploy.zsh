# The deploy fixture: @kud/ink-ui's help.golden/deploy.json as shui help flags.
# Sourced by tests/test-help.zsh; the deploy.*.txt beside it are ink-ui's bytes.
shui help \
  --name 'deploy' \
  --version '2.4.0' \
  --desc 'Ship a build to an environment' \
  --usage 'deploy [options] <target> [files…]' \
  --usage 'deploy rollback [release]' \
  --about 'A target is a named environment from deploy.toml; files default to everything the build produced.' \
  --command 'rollback [release]|Return to a previous release, the last one by default' \
  --command 'status|Show what is live in each environment' \
  --argument '<target>|Environment to deploy to' \
  --argument '[files…]|Files to include' \
  --option '-p, --port <number>|Port the health check listens on|3000' \
  --option '--dry-run|Print the plan without applying it' \
  --option '-v, --verbose|Log every request' \
  --option '--region <name>|Cloud region for the deploy, which also decides where logs and artefacts are kept|eu-west-1' \
  --option '--max-parallel-uploads <n>|Upload at most this many files at once|8' \
  --option '-h, --help|Show this help' \
  --example 'Deploy the current build to staging|deploy staging' \
  --example 'See what would change in production|deploy production --dry-run' \
  --env 'DEPLOY_TOKEN|Token used to authenticate' \
  --env 'NO_COLOR|Turn colour off; bold is kept' \
  --see 'https://kud.io/projects/deploy' \
  --see 'deploy.toml(5)'
