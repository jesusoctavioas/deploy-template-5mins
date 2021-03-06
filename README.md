# The 5 Minute Production App

**Quickly** make a **stateful** app that is deployed on a **hypercloud**.

### Quickly

If you have written an application you should be able to deploy it within minutes with the 5-minute production app.
Many other platforms are also quick, for example Heroku. 
But configuring Heroku for a production application that needs statefulness (remembering users and data across deploys) is a much longer process.
And Heroku doesn't let you deploy on a hypercloud, which has [many advantages](#hypercloud).

### Stateful

The 5 minute production app uses the managed stateful services of a hypercloud so your data is persisted and secure.
By leveraging these managed services (databases, caching, objects storage, etc.) you have less to maintain.
Everything is provisioned through Terraform which has the following advantages:

1. Terraform is the most popular IaC tool.
1. Terraform works across platforms.
1. Terraform state can be [stored and viewed in GitLab](https://docs.gitlab.com/ee/user/infrastructure/#gitlab-managed-terraform-state).
1. You avoid the cost and complexity of Kubernetes.
1. You have complete control to customize and extend.

### Hypercloud

Most people working in organizations use the three western hyper clouds (AWS, Azure, GCP) because: 

1. They have a wide selection of managed stateful services (databases, caching, object storage, etc.).
1. At least one is probably already approved to be used in your organization.
1. At least one is probably already budgeted for.
1. They have a free tier which the 5 minute production app runs within.
1. They are familiar to other people in your team and organization.
1. They are reliable and secure.
1. They are quickly innovating (machines with ARM processors, GPUs, TPUs, etc.).
1. They have lower prices than services such as Heroku.
1. They allow applications room to grow, no need to move from Heroku to AWS when it becomes popular.

### Ops2Dev Philosophy

The hardest thing about an application is not the initial deploy, it's maintaining the application over time.
The 5 minute production app brings your Day 2 operations into Day 1 and makes [Day 2 operations simple](https://about.gitlab.com/topics/gitops/gitlab-enables-infrastructure-as-code/).
Use managed services as you develop, and your infrastructure scales with you.

We are working to optimize the 5 minute production app so that you'll be moving just as quickly as you would on a typical Day 1.

### Relation to Auto DevOps

1. [Auto DevOps](https://about.gitlab.com/stages-devops-lifecycle/auto-devops/) provides point-and-click default CI/CD templates that auto-discover your source code to detect, build, test, deploy, and monitor your applications automatically.
1. Auto DevOps is already [quick and easy to get started with](https://docs.gitlab.com/ee/topics/autodevops/#quick-start) by default.
1. Auto DevOps is stateless, however, the 5 minute production app is stateful.
1. Auto DevOps uses Kubernetes, which you can use on hyper cloud, but only the 5 minute production app gives you:
   1. The ability to use managed stateful services (databases, caching, object storage, etc.) by default.
   1. A free tier which the 5 minute production app runs within. Kubernetes isn't part of a free tier for any hyper cloud.
1. No Kubernetes overhead reduces cost and makes it simpler to run.
1. The objective is to eventually combine Auto DevOps and the 5 minute production app so that [everyone can contribute](https://about.gitlab.com/company/strategy/#everyone-can-contribute) using Auto DevOps in production more easily.


### Roadmap

You're looking at the primary project for the 5 minute production app.
The roadmap in [its issue board](https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/boards)

### Vision

- [Category direction](https://about.gitlab.com/direction/5-min-production/)
- [Blog: A journey from the first code to CI/CD deployments in 5 minutes?](https://about.gitlab.com/blog/2020/12/15/first-code-to-ci-cd-deployments-in-5-minutes/)
- [Meeting playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0Krf0LZbfg80yo08DW1c3C36)

#### Usage Charts

You may use the [5 Minute Production Application Sisense Dashboard](https://app.periscopedata.com/shared/b0987d39-f197-47ca-b830-edd9ea14d2fe) to see the usage for the Sisense.


### Table of Contents

1. [Video Overview](#video-overview)
1. [Prerequisites](#prerequisites)
1. [Infrastructure](#infrastructure)
1. [Usage](#usage)
1. [Environments](#environments)
1. [Using the Postgres Database](#using-the-postgres-database)
1. [Using the S3 Bucket](#using-the-s3-bucket)
1. [Using the SMTP Service](#using-the-smtp-service)
1. [Using the Redis Cluster](#using-the-redis-cluster)
1. [Providing Custom Environment Variables to Webapp](#providing-custom-environment-variables-to-webapp)
1. [Variables Provided to Webapp](#variables-exposed-to-webapp)
1. [Rollback Deployments](#rollback-deployments)
1. [Configure Infra Resources](#configure-infra-resources)
1. [List of All Configuration Variables](#list-of-all-configuration-variables)
1. [Custom domain](#custom-domain)
1. [Enabling SSL](#enabling-ssl)
1. [Variables](#variables)
1. [Examples](#examples)
1. [Feedback](#feedback)
1. [Contributing](#contributing)

### Video Overview

[![Five Minute Production](http://img.youtube.com/vi/XcDN4bx7sNs/0.jpg)](http://www.youtube.com/watch?v=XcDN4bx7sNs "Five Minute Production")

### Prerequisites

1. You have a Dockerized webapp with a `Dockerfile` or [Auto Build](https://docs.gitlab.com/ee/topics/autodevops/stages.html#auto-build) works for your application.
1. Your containerized app runs on port 5000 (default setting for Auto Build) or `WEBAPP_PORT` is set in `.gitlab-ci.yml`

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
- (Optional) SMTP service
- (Optional) Redis service

### Usage

1. Set the following [AWS](https://aws.amazon.com/) credentials as [GitLab CI/CD environment variables](https://docs.gitlab.com/ee/ci/variables/) which you can find under Project => Settings => CI/CD => Variables. If you want to have [review apps](https://docs.gitlab.com/ee/ci/review_apps/) make sure to not [protect the variable](https://docs.gitlab.com/ee/ci/variables/#protect-a-custom-variable).
  - `AWS_ACCESS_KEY_ID` which you can create in [AWS IAM under Access Keys](https://console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials$access_key). You need to have sufficient permissions for the AWS IAM user to successfuly create resources like RDS or EC2. If you are not sure what correct permissions are then use `AdministratorAccess` as a temporay solution.
  - `AWS_SECRET_ACCESS_KEY` which you can create in [AWS IAM under Access Keys](https://console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials$access_key)
  - `AWS_DEFAULT_REGION` which is optional and defaults to us-east-1 if not set

![frame_generic_light_2__compressed](/uploads/ad33728c14f28f44c23362d86cadd816/frame_generic_light_2__compressed.png)

2. Create a `.gitlab-ci.yml` file in project root with 5-minute production app [CI template](https://docs.gitlab.com/ee/ci/examples/#cicd-templates) like shown on the picture below:

![frame_generic_light_compressed](/uploads/91fe1bea95dc1f018bf021e81f4c6823/frame_generic_light_compressed.png)

But if you want to use the latest version of template you should create a `.gitlab-ci.yml` file with the following content: 

```yaml
include:
  remote: https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/raw/stable/deploy.yml
```

This is a good choice for development and testing. Or if your GitLab version is not the latest one. 


3. After the `.gitlab-ci.yml` file is added to the repository a new [pipeline](https://docs.gitlab.com/ee/ci/pipelines/) will start which you can see under the menu CI/CD => Pipelines. When the pipeline completed successful a link to your running application will be available from the menu Operations => Environments => master => View Environment.

![frame_generic_light_4__compressed](/uploads/182a5b979f3f35fa164ff5cddf071caf/frame_generic_light_4__compressed.png)

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
  - `DB_INITIALIZE` is executed only once on first deploy, and if successful, will never be executed
    again
    - If the first execution of `DB_INITIALIZE` fails, it will be retried on next deployment
    - `DB_INITIALIZE` can be force-executed if `DB_INITIALIZE_REPEAT` is set to `"True"`
  - `DB_MIGRATE` is executed on every deployment
  - Failing `DB_INITIALIZE` or `DB_MIGRATE` **will not** rollback your deployment

### Using the S3 Bucket

An S3 Bucket is generated for your webapp with `public-read` settings. The following env vars are
made available to your app for use: `S3_BUCKET`, `S3_BUCKET_DOMAIN` and `S3_BUCKET_REGIONAL_DOMAIN`.

You will need to use your AWS credentials in addition to the S3 Bucket name for uploading content.

### Using the SMTP Service

AWS SES provides SMTP service. This service is made available to your webapp if you declare the `SMTP_FROM` variable.

`SMTP_FROM` is an email address that is the sender of emails by your webapp. AWS SES will require this email to be 
verified. In sandbox mode, the recipient emails also need to be verified. To turn off sandbox mode, please log in to your AWS 
console and configure SES. Read more at [Amazon Simple Email Service documentation](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html).

### Using the Redis Cluster

A Redis Elasticache cluster will be provisioned for your application with REDIS_NODE_TYPE `cache.t2.micro`. Once
provisioned, the environment variables `REDIS_ADDRESS`, `REDIS_PORT`, `REDIS_AVAILABILITY_ZONE` and `REDIS_URL` are made
available to your webapp.

### Providing Custom Environment Variables to Webapp

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
- DATABASE_ADDRESS              # {db_host}
- DATABASE_USERNAME             # {db_user}
- DATABASE_PASSWORD             # {db_pass}
- DATABASE_NAME                 # {db_name}

- AWS_ACCESS_KEY_ID             # Your AWS access key
- AWS_SECRET_ACCESS_KEY         # Your AWS access key
- AWS_DEFAULT_REGION            # Your AWS region

- S3_BUCKET                     # Environment specific S3 bucket name
- S3_BUCKET_DOMAIN              # Publicly accessible domain
- S3_BUCKET_REGIONAL_DOMAIN     # Publicly accessible regional domain

- SMTP_HOST                     # AWS SES SMTP server, region specific
- SMTP_FROM                     # AWS SES validated from email address
- SMTP_USER                     # SMTP user
- SMTP_PASSWORD                 # SMTP password

- REDIS_ADDRESS                 # Address of your Redis cluster
- REDIS_PORT                    # Port of your Redis cluster
- REDIS_AVAILABILITY_ZONE       # Availability zone in case location of data storage matters
- REDIS_URL                     # Redis hostname and port separated with a `:`

- GL_VAR_*                      # All variables prefixed with `GL_VAR_`
```

### Rollback Deployments

- Clean way to rollback is to push a revert commit

### Configure Infra Resources

You can set the environment variables `TF_VAR_EC2_INSTANCE_TYPE`, `TF_VAR_PG_INSTANCE_CLASS`
and `TF_VAR_PG_ALLOCATED_STORAGE` to explicitly define the specs of infra that is provisioned.

Default values are shown in the [configuration example](#list-of-all-configuration-variables).

### List of All Configuration Variables

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
  TF_VAR_PG_INSTANCE_CLASS: "db.t2.micro"  # free tier
  TF_VAR_PG_ALLOCATED_STORAGE: 20          # 20gb
  TF_VAR_DISABLE_POSTGRES: "false"

  # ssl certificates
  CERT_DOMAIN: 'my-domain.com'
  CERT_EMAIL: 'admin@my-domain.com'

  # smtp
  SMTP_FROM: 'notifications@my-company.com'

  # redis
  TF_VAR_REDIS_NODE_TYPE: 'cache.t2.micro'
  TF_VAR_DISABLE_REDIS: "false"

  # pass custom variables to webapp
  GL_VAR_HELLO: World
  GL_VAR_FOO: Bar
```

### Cleanup

The pipeline includes `destroy` job that will remove all infrastructure created by `terraform_apply`
. To prevent accidental removal of production data, we disabled `destroy` job on protected branches.
However you can always start pipeline with `CI_COMMIT_REF_PROTECTED` variable set to `false`. This
will add `destroy` job to pipeline (you still need to manually trigger it) so you can remove
infrastructure even on protected branch.

### Custom domain

By default the deployment uses EC2 ip address and generates a domain name for it. 
For custom domain see [Enabling SSL](#enabling-ssl). 

### Enabling SSL

- SSL is enabled for all environments
- By default, the URL structure is `https://{branch-or-tag}.{public-ip}.resolve.toip.host`
- For custom domain, define `CERT_DOMAIN` variable for your pipeline
  - This can be defined in `.gitlab-ci.yml` alongwith `CERT_EMAIL`

### Variables

You can find a list of all variables this project uses [here](VARIABLES.md)

### Examples

Examples across multiple programming languages and web frameworks are listed in
the [examples subgroup](https://gitlab.com/gitlab-org/5-minute-production-app/examples).

Additional experiments and test cases are located in
the [sandbox subgroup](https://gitlab.com/gitlab-org/5-minute-production-app/sandbox).

We also collected helpful information on specific languages and frameworks:

* [Ruby on Rails](RAILS.md)

If you have experience with different language/framework, please contribute to the list above, 
we especially welcome Node, Go, Spring, Django, and Phoenix examples.

Simply create a file `NAME_OF_LANGUAGE_OR_FRAMEWORK.md` and put a link in the list.

### Feedback

This project is in early stage of development. And we are looking for your feedback. 
If everything worked well for you, feel free to mention @gitlab, @srirangan or @dzaporozhets in social networks. 
But if you experience any problems or have suggestions, please open an issue in this project.  

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
