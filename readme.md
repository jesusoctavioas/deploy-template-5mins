# Five Minute Docker

### Objective

To build a pipeline that will:

- Build a Dockerfile
    - and publish it to the Container Registry
- Spin up infra on AWS
    - Generate SSH keys
    - Provision EC2 instance
    - Provision Postgres (RDS)
- Configure EC2 instance:
    - Install Docker
    - Connect with GitLab Container Registry
    - Setup `DATABASE_URL`
- Deploy dockerized app
