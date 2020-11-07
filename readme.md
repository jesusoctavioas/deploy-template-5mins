# Five Minute Docker

Five Minute Docker allows Dockerized applications to be deployed on production grade AWS infrastructure in under five
minutes.

## Users Guide

### Assumption

You have a Dockerized webapp with a `Dockerfile`.

### Infrastructure

We provision for you:

1. AWS EC2 instance
    - Amazon Linux
    - `t2.micro`
    - Public IP
2. AWS DB instance
    - Postgres
    - `db.t2.small`
    - 20gb allocated storage

### Usage

1. Setup AWS credentials in your GitLab Project or Group CICD variables
    - `GitLab Group :: Settings :: CICD :: Variables`
    - `GitLab Project :: Settings :: CICD :: Variables`
    - Variables to declare:
        - `AWS_ACCESS_KEY`
        - `AWS_SECRET_KEY`
        - `AWS_REGION`
2. Check again if you have the pre-requisite Dockerfile in your project
    - Test it locally
    - Make sure your app works with Docker
3. Create `.gitlab-ci.yml` file in project root, and consume Five Minute Docker with `includes`
    ```yaml
    variables:
        #AWS_ACCESS_KEY: ".."     # defined elsewhere
        #AWS_SECRET_KEY: ".."     # defined elsewhere
        #AWS_REGION: ".."         # defined elsewhere
        WEBAPP_PORT: 5000
    
    include:
        remote: https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/five-minute-docker/-/raw/master/five-minute-docker.gitlab-ci.yml
    ```
4. Update the `WEBAPP_PORT` variable to match the port exposed in your Dockerfile
5. Finally, `commit` changes, `push` to GitLab and watch GitLab pipeline deploy your project

### Examples

- [Python w/ Flask](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/python-in-five)
- Python w/ Django
- Python w/ FastAPI
- [Node.js w/ Connect](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/node-in-five)
- Node.js w/ Express
- Node.js w/ Next.js
- Ruby on Rails
- Clojure w/ Luminus

## Maintainers Guide

### Roadmap

- [ ] Expose variables for consumer to tweak AWS infra attributes
- [ ] Build a detailed example and show how...
    - [ ] Database migrations would work
    - [ ] Automated testing would work
    - [ ] Other Auto DevOps jobs can be integrated
- [ ] Deploy the app behind a Nginx proxy
- [ ] Enable SSL with Letsencrypt

MRs welcome.
