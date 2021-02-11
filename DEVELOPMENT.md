# Changing resolver (wildcard dns) domain

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
