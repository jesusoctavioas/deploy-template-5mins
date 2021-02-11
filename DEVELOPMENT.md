# Development documentation

## Branches

We have permanent branches `master` and `stable`. Our users use `stable` branch by default. This means we can test all new changes in `master` branch without breaking deployment for our users. 

To use `master` branch you must include 5 minute production app directly from this repository:

```yml
include:
  remote: https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/raw/stable/deploy.yml
```

To deliver new features and fixes to our users, a merge request from `master` to `stable` branch must be created. Such merge request should be assigned to a maintainer. 

## Modifying deploy.yml file

Better don't change it. But if you really need to, make sure to read the text below. 

Keep in mind that `deploy.yml` file in the root of this repository is duplicated in GitLab main repo by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49487. So every change you make to `deploy.yml` won't take effect on our users if they created `gitlab-ci.yml` through that template suggestion. That means those users always have latest version from stable branch but with outdated `deploy.yml`. So whenever you make a change to `deploy.yml` make sure the rest of the code can still work with old `deploy.yml`.    

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
