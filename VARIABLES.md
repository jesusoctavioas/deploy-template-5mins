# Variables

Below is the list of all variables this project uses. Some of them are required, the rest is
optional and exist to provide additional functionality or flexibility.

| Variable      | Description | Example value | Required |  Pipeline variable | Webapp variable |
| ------------- | ----------- | -------- | ------------- | ------------------ | --------------- |
| AWS_ACCESS_KEY_ID | Your AWS security credentials  | `AKIAIOSFODNN7EXAMPLE` | Required | Yes | Yes |
| AWS_SECRET_ACCESS_KEY | Your AWS security credentials  |  `wJalrXUtnFEMI /K7MDENG /bPxRfiCYEXAMPLEKEY` | Required | Yes | Yes |
| AWS_DEFAULT_REGION | Your AWS region  | `us-west-2` | Required | Yes | Yes |
| CERT_EMAIL | HTTPS Your email to generate ssl certificate.  | `dz@example.com` | | Yes | |
| CERT_DOMAIN | HTTPS Domain name for your app.  | `example.com` |  | | Yes |
| DATABASE_URL | Generated postgresql credentials  | We generate it for you. |  | | Yes |
| DATABASE_ENDPOINT | Generated postgresql host and port  | We generate it for you. |  | | Yes |
| DATABASE_ADDRESS | Generated postgresql host  | We generate it for you. |  | | Yes |
| DATABASE_USERNAME | Generated postgresql username  | We generate it for you. |  | | Yes |
| DATABASE_PASSWORD | Generated postgresql password  | We generate it for you. |  | | Yes |
| DATABASE_NAME | Generated postgresql db name  | We generate it for you. |  | | Yes |
| DB_INITIALIZE | This command will be executed once after deployment. | `bin/rake db:setup RAILS_ENV=production` |  | Yes | |
| DB_MIGRATE | This command will be executed after each deployment. | `bin/rake db:migrate RAILS_ENV=production` |  | Yes | |
| S3_BUCKET | S3 environment specific bucket name. | We generate it for you. |  | | Yes |
| S3_BUCKET_DOMAIN | S3 publicly accessible domain. | We generate it for you. |  | | Yes |
| S3_BUCKET_REGIONAL_DOMAIN | S3 publicly accessible regional domain. | We generate it for you. |  | | Yes |
| TF_VAR_EC2_INSTANCE_TYPE | EC2 instance size. Your app will run on it  | `t2.micro` |  | Yes | |
| TF_VAR_PG_INSTANCE_CLASS | Database instance size  | `db.t2.micro` |  | Yes | |
| TF_VAR_PG_ALLOCATED_STORAGE | Database storage size  | `20gb` |  | Yes | |
| TF_VAR_REDIS_NODE_TYPE | Size of the Redis node, possible values [aws.amazon.com/elasticache/pricing](https://aws.amazon.com/elasticache/pricing/) If undefined, Redis / Elasticache is not provisioned | `cache.t2.micro` | | Yes | |
| WEBAPP_PORT | Your application port according to the Dockerfile   | `5000` |  | Yes | |
| SMTP_HOST | AWS SES SMTP server, region specific   | We generate it for you. |  | | Yes |
| SMTP_FROM | AWS SES validated from email address   | `notifications@my-company.com` | | Yes | Yes |
| SMTP_USER | SMTP user name   | We generate it for you. | | | Yes |
| SMTP_PASSWORD | SMTP password   | We generate it for you. | | | Yes |
| REDIS_ADDRESS | Address of your Redis cluster | We generate it for you. | | | Yes |
| REDIS_PORT | Port of your Redis cluster | We generate it for you. | | | Yes |
| REDIS_AVAILABILITY_ZONE | Availability zone of your Redis cluster | We generate it for you. | | | Yes |
| REDIS_URL | Hostname and port of Redis separated by `:` | We generate it for you. | | | Yes |
