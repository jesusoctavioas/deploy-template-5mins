# Deploy Template for 5 Minute Production App

Five Minute Docker allows Dockerized applications to be deployed on production grade AWS
infrastructure in under five minutes.

- [Assumption](#assumption)
- [Infrastructure](#infrastructure)
- [Usage](#usage)
- [Pipeline](#pipeline)
- [Environments](#environments)
- [Using the Postgres Database](#using-the-postgres-database)
- [Using the S3 Bucket](#using-the-s3-bucket)
- [Providing Custom Environment Variables to Webapp](#providing-custom-environment-variables-to-webapp)
- [Variables Provided to Webapp](#variables-exposed-to-webapp)
- [Rollback Deployments](#rollback-deployments)
- [Customizing the Port](#customizing-the-port)
- [List of All Configuration Variables](#list-of-all-configuration-variables)
- [Examples](#examples)

### Assumption

You have a Dockerized webapp with a `Dockerfile`.

Your webapp is expected to run on port `5000`, however this can
be [configured](#list-of-all-configuration-variables).

### Infrastructure

By default, the following AWS free tier infrastructure is provisioned:

- Elastic IP
- EC2 instance
    - Amazon Linux
    - `t2.micro`
    - Public IP
- DB instance
    - Postgres
    - `db.t2.micro`
    - 20gb allocated storage
- S3 Bucket

### Usage

1. Setup AWS credentials in your GitLab Project or Group CICD variables
    - Variables to declare:
        - `AWS_ACCESS_KEY`
        - `AWS_SECRET_KEY`
        - `AWS_REGION`
2. Create `.gitlab-ci.yml` file in project root, and `include` Five Minute Docker:

```yaml
include:
    remote: https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/raw/master/deploy.yml
```

3. Finally, `commit` changes, `push` to GitLab

### Pipeline

The `include::remote` directive above includes a pipeline into your project. This pipeline is
responsible for provisioning infrastructure, configuring and deploying your containerized webapp.

Stages and jobs of the pipeline are explained below (in a simplified manner):

- Stage 1: `Build`
    - Job `Docker Build` builds the Dockerfile and pushes the image to the project specific
      container registry
    - Job `AWS Provision` provisions the infra defined in `infra.tf`
- Stage 2: `Deploy`
    - Job `Deploy App`
        - SSHs into EC2 instance
        - Logs into your project's container registry
        - Pulls and runs the latest container image for that environment
        - If configured, executes `DB_INITIALIZE` and `DB_MIGRATE`
- Stage 3: `Destroy`
    - Job `Destroy` can be manually triggered to destroy all provisioned infrastructure
        - When Merge Request is merged, `Destroy` is automatically triggered to tear down the review
          environment.

### Environments

- Pipeline automatically creates `environments`
    - `environment = infrastructure + data + configuration + deployed webapp`
- Multiple `environments` are supported
    - `environments` are synced with git branches
    - One environment per branch
- Environment name matches `$CI_COMMIT_REF_SLUG` i.e. branch name or tag name, lowercased and
  slugified, for example:
    - `production` branch will create and deploy to `production` environment
    - `staging` branch will create and deploy to `staging` environment, etc.

### Using the Postgres Database

- `DATABASE_URL` is passed to the webapp container
    - Format: `postgres://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}`
- Individual variables are also passed to the webapp container:
    - `DATABASE_ENDPOINT`
    - `DATABASE_USERNAME`
    - `DATABASE_PASSWORD`
    - `DATABASE_NAME`
- Environment variables `DB_INITIALIZE` and `DB_MIGRATE`, if set, are executed right
  after `docker run`
    - These must contain commands that are executed after deployment
    - These commands are executed within the Docker container
    - `DB_INITIALIZE` is executed only once on first deploy, and if successful, will never be
      executed again
        - If the first execution of `DB_INITIALIZE` fails, it will be retried on next deployment
        - `DB_INITIALIZE` can be force-executed if `DB_INITIALIZE_REPEAT` is set to `"True"`
    - `DB_MIGRATE` is executed on every deployment
    - Failing `DB_INITIALIZE` or `DB_MIGRATE` **will not** rollback your deployment

### Using the S3 Bucket

An S3 Bucket is generated for your webapp with `public-read` settings. The following env vars are
made available to your app for use: `S3_BUCKET`, `S3_BUCKET_DOMAIN` and `S3_BUCKET_REGIONAL_DOMAIN`.

You will need to use your AWS credentials in addition to the S3 Bucket name for uploading content.

#### Providing Custom Environment Variables to Webapp

Your application might need custom environment variables. These can be passed by declaring them with
the `GL_VAR_` prefix. For example, if you wanted to pass `HELLO=WORLD`, you will need to
declare `GL_VAR_HELLO=WORLD`.

This can be done in two ways:

- Define them in the `.gitlab-ci.yml` file (as shown in
  the [example](#list-of-all-configuration-variables)), or
- Define them in the project or group environment variables set through the GitLab Web UI

**Caution** Make sure your env-var values are properly escaped. The value will be wrapped in a pair
of double-quotes `HELLO="world"` and improper escaping of value can break the deployment.

### Variables Exposed to Webapp

The following variables are provided to your containerized webapp. Thus are available at runtime.

```yaml
- DATABASE_URL                  # postgres://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}
- DATABASE_ENDPOINT             # {db_host}:{db_port}
- DATABASE_USERNAME             # {db_user}
- DATABASE_PASSWORD             # {db_pass}
- DATABASE_NAME                 # {db_name}

- AWS_ACCESS_KEY                # Your AWS access key
- AWS_SECRET_KEY                # Your AWS access key
- AWS_REGION                    # Your AWS region

- S3_BUCKET                     # Environment specific S3 bucket name
- S3_BUCKET_DOMAIN              # Publicly accessible domain
- S3_BUCKET_REGIONAL_DOMAIN     # Publicly accessible regional domain

- GL_VAR_*                      # All variables prefixed with `GL_VAR_`
```

#### Rollback Deployments

- Clean way to rollback is to push a revert commit

### Customizing the Port

By default, the containerized app's port 5000 is exposed. This can be modified by explicitly
defining `WEBAPP_PORT` in your `.gitlab-ci.yml`

#### Configure Infra Resources

You can set the environment variables `TF_VAR_EC2_INSTANCE_TYPE`, `TF_VAR_POSTGRES_INSTANCE_CLASS`
and `TF_VAR_POSTGRES_ALLOCATED_STORAGE` to explicitly define the specs of infra that is provisioned.

Default values are shown in the [configuration example](#list-of-all-configuration-variables).

#### List of All Configuration Variables

The following variables can be defined in your `.gitlab-ci.yml` file or be made available to the
pipeline through any other mechanism. These variables are meant to configure the infrastructure or
deployment process.

```yaml
variables:

    # executed successfully once after deployment
    DB_INITIALIZE: "bundle exec rake db:setup RAILS_ENV=production"

    # force DB_INITIALIZE execution
    DB_INITIALIZE_REPEAT: "True"

    # executed after every deployment
    DB_MIGRATE: "bundle exec rake db:migrate RAILS_ENV=production"

    # configure container port bindings
    WEBAPP_PORT: 3000

    # configure infra specifications
    TF_VAR_EC2_INSTANCE_TYPE: "t2.micro"           # free tier
    TF_VAR_POSTGRES_INSTANCE_CLASS: "db.t2.micro"  # free tier
    TF_VAR_POSTGRES_ALLOCATED_STORAGE: 20          # 20gb

    # pass custom variables to webapp
    GL_VAR_HELLO: World
    GL_VAR_FOO: Bar
```

### Examples

Examples across multiple programming languages and web frameworks are listed in
the [examples subgroup](https://gitlab.com/gitlab-org/5-minute-production-app/examples).

Additional experiments and test cases are located in
the [sandbox subgroup](https://gitlab.com/gitlab-org/5-minute-production-app/sandbox).
