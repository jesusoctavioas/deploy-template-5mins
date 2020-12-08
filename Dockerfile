FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY variables.tf .
COPY main.tf .
COPY outputs.tf .

COPY deploy.sh .
COPY setup_instructions.sh .
COPY ssl_certificate.sh .

COPY conf.nginx .
COPY nossl.conf.nginx .

RUN chmod a+x deploy.sh
RUN chmod a+x  setup_instructions.sh .
RUN chmod a+x  ssl_certificate.sh .
