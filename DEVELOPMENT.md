# Development documentation

## Branches

We have permanent branches `master` and `stable`. Our users use `stable` branch by default. That means we can test all new changes in `master` branch before delivering it to our users. 

To use `master` branch you must include 5 minute production app directly from this repository:

```yml
include:
  remote: https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/raw/stable/deploy.yml
```

To deliver new features and fixes to our users, a merge request from `master` to `stable` branch must be created. Assign the merge request to the maintainer. 

## Changing resolver (wildcard dns) domain

If you need to change the default domain name used by 5 minute production app, you can use this commit as example: 
https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/commit/8be5d5385625ff65ed8b5bd149284a12a877f83c. 

If you want to use a custom domain name resolver (aka wildcard dns) in specific project you can use `FALLBACK_DYNAMIC_DOMAIN` variable. 

Example: 

```yml
variables:
    FALLBACK_DYNAMIC_DOMAIN: "resolve.anyip.host"

include:
  - template: 5-Minute-Production-App.gitlab-ci.yml
```
