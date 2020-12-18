FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY *.tf .
COPY deploy.sh .
COPY conf.nginx .

RUN chmod a+x deploy.sh
