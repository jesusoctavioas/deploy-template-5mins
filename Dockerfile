FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY deploy.sh .
COPY variables.tf .
COPY main.tf .
COPY outputs.tf .
COPY conf.nginx .

RUN chmod a+x deploy.sh
