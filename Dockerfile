FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY main.tf .
COPY outputs.tf .
COPY resource_db.tf .
COPY resource_ec2.tf .
COPY resource_s3.tf .
COPY resource_ses.tf .
COPY variables.tf .

COPY deploy.sh .
COPY conf.nginx .

RUN chmod a+x deploy.sh
