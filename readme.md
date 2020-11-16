# Five Minute Docker

Five Minute Docker allows Dockerized applications to be deployed on production grade AWS infrastructure in under five
minutes.

- [Assumption](#assumption)
- [Infrastructure](#infrastructure)
- [Usage](#usage)
- [How It Works](#how-it-works)
    - [Stages](#stages)
        - [Build](#build)
        - [Deploy](#deploy)
        - [Destroy](#destroy)
    - [Environments](#environments)
    - [Database](#database)
    - [Port](#port)
    - [Custom Environment Variables](#custom-environment-variables)
    - [Customizing](#configuration-example)
- [Examples](#examples)

### Assumption

You have a Dockerized webapp with a `Dockerfile`.

Your webapp is expected to run on port `5000`, however this can be [configured](#configuration-example).

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
    remote: https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/raw/master/deploy.gitlab-ci.yml
#   template: five-minute-production.gitlab-ci.yml
```

3. Finally, `commit` changes, `push` to GitLab

### How It Works

#### Stages

1. Build
2. Deploy
3. Destroy
   
##### Build

- `Docker Build Push` builds the Dockerfile and pushes the image to the project specific container registry
- `AWS Provision` provisions the infra defined in `infra.tf`

##### Deploy

- `Deploy App`
    - SSHs into EC2 instance
    - Logs into Docker with project specific Container Registry access
    - Pulls container image
    - Runs container images
    - If available, executes `DB_INITIALIZE` and `DB_MIGRATE`
    - Finally, GitLab Environment is created for deployment

##### Destroy

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
- This enables your webapp connect to the Postgres instance that was generated
- Environment variables `DB_INITIALIZE` and `DB_MIGRATE`, if set, are executed right after `docker run`
    - These must contain commands that are executed after deployment every time
    - These commands are executed within the Docker container
- `DB_INITIALIZE` is executed only once on first deploy, and if successful, will never be executed again
    - If the first execution of `DB_INITIALIZE` fails, it will be retried on next deployment
- `DB_MIGRATE` is executed on every deployment

#### Port

By default, the containerized app's port 5000 is exposed. This can be modified by explicitly defining `WEBAPP_PORT` in
your `.gitlab-ci.yml`

#### Custom Environment Variables

Your application might need custom environment variables. These can be passed by declaring them with the `GL_VAR_` prefix. For example, if you wanted to pass `HELLO=WORLD`, you will need to declare `GL_VAR_HELLO=WORLD`.

This can be done in two ways:
- Define them in the `.gitlab-ci.yml` file (as shown in the [example](#configuration-example)), or 
- Define them in the project or group environment variables set through the GitLab Web UI

**Caution** Make sure your env-var values are properly escaped. The value will be wrapped in a pair of double-quotes `HELLO="world"` and improper escaping of value can break the deployment.

#### Configuration Example

```yaml
variables:
    DB_INITIALIZE: "bundle exec rake db:setup RAILS_ENV=production"
    DB_MIGRATE: "bundle exec rake db:migrate RAILS_ENV=production"
    WEBAPP_PORT: 3000
    GL_VAR_HELLO: World
    GL_VAR_FOO: Bar
```

### Examples

- [Python w/ Flask](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/python-in-five)
- [Node.js w/ Connect](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/sri-stuff/node-in-five)
- [Ruby on Rails](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/dz-rails-3/)
- [Clojure Web App](https://gitlab.com/gitlab-org/creator-pairing/5-minute-prod-app/clojure-web-application/)
