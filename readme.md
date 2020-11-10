# Five Minute Docker

Five Minute Docker allows Dockerized applications to be deployed on production grade AWS infrastructure in under five
minutes.

## Index

- [Users Guide](#users-guide)
    - [Assumption](#assumption)
    - [Infrastructure](#infrastructure)
    - [Usage](#usage)
    - [How It Works](#how-it-works)
        - [Stages](#stages)
        - [Environments](#environments)
        - [Database](#database)
    - [Examples](#examples)
- [Maintainers Guide](#maintainers-guide)
    - [Roadmap](#roadmap)

## Users Guide

### Assumption

You have a Dockerized webapp with a `Dockerfile`.

### Infrastructure

By default, the following AWS free tier infrastructure is provisioned:

- EC2 instance
    - Amazon Linux
    - `t2.micro`
    - Public IP
- DB instance
    - Postgres
    - `db.t2.micro`
    - 20gb allocated storage
    
### Usage

1. Setup AWS credentials in your GitLab Project or Group CICD variables
    - Variables to declare:
        - `AWS_ACCESS_KEY`
        - `AWS_SECRET_KEY`
        - `AWS_REGION`
    - `GitLab Group :: Settings :: CICD :: Variables`
    - `GitLab Project :: Settings :: CICD :: Variables`
2. Create `.gitlab-ci.yml` file in project root, and `include` Five Minute Docker:
```yaml
include:
    remote: https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/five-minute-docker/-/raw/master/five-minute-docker.gitlab-ci.yml
#   template: five-minute-production.gitlab-ci.yml
```
3. Finally, `commit` changes, `push` to GitLab

### How It Works

#### Stages

1. Stage: `Build`
    - `Docker Build Push` builds the Dockerfile and pushes the image to the project specific container registry
    - `AWS Provision` provisions the infra defined in `infra.tf`
2. Stage: `Deploy`
    - `Deploy App` 
        - SSHs into EC2 instance
        - Logs into Docker with project specific Container Registry access
        - Pulls container image
        - Runs container images
        - If available, executes `DB_INITIALIZE` and `DB_MIGRATE`
        - Finally, GitLab Environment is created for deployment
3. Stage: `Destroy`
    - `Destroy` is manually triggered to destroy all provisioned infrastructure

#### Environments

- Multiple `environments` are supported and linked to git branching i.e. one environment per branch
- Pipeline automatically creates environments
- Environment name matches `$CI_COMMIT_REF_SLUG` i.e. branch name or tag name, lowercased and slugified, for example:
    - `production` branch will create and deploy to `production` environment
    - `staging` branch will create and deploy to `staging` environment, etc.

#### Database

- `DATABASE_URL` is passed to the webapp container
    - Format: `postgres://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}`
- Environment variables `DB_INITIALIZE` and `DB_MIGRATE`, if set, are executed right after `docker run`.
    - These must contain commands that are executed after deployment every time
    - These commands are executed within the Docker container

### Examples

- [Python w/ Flask](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/python-in-five)
- [Node.js w/ Connect](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/node-in-five)

## Maintainers Guide

### Roadmap

- Parity with Auto DevOps?
    - Support domain names and generate SSLs
        - How must the user configure domain?
        - And the corresponding email for SSL?
            - Read GitLab user email?
    - Deployment rollbacks
    - Logging
    - Monitoring
    - Destroy environment on Merge Request `merge` event
- Integration with GitLab stages and features:
    - [x] Environments
    - [x] Container Registry
    - [x] Managed Terraform State
    - [ ] Verify Stage
        - [ ] Code Quality
        - [ ] Testing & Coverage
        - [ ] Load Testing, Web performance, Accessibility Testing
    - [ ] Secure Stage
        - [ ] Container Scans
        - [ ] SAST
        - [ ] Secrets Scans
        - [ ] Dependency Scans
        - [ ] License Compliance (is this relevant for target user?)
- Support AWS free tier services
    - [x] AWS EC2
    - [x] AWS DB Instance
    - [ ] Amazon S3 (Static file storage)
    - [ ] Amazon SNS (Push messages)
    - [ ] Amazon SES (Email service)
    - [ ] Amazon SQS (Message queue)
