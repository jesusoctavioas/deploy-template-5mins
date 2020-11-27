FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

COPY deploy.sh .
COPY infra.tf .

CMD ["gitlab-terraform", "init"]
