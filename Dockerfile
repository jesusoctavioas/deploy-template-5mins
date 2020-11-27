FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY deploy.sh .
COPY infra.tf .

RUN chmod a+x deploy.sh

CMD ["gitlab-terraform", "init"]
