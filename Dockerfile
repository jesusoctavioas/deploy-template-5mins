FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY variables.tf .
COPY main.tf .
COPY outputs.tf .

COPY deploy.sh .
COPY setup_instructions.sh .
COPY ssl_certificate.sh .

COPY conf.nginx .

RUN chmod a+x deploy.sh
