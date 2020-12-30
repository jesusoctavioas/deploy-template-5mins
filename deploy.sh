# extract terraform state
gitlab-terraform output -json >tf_output.json
jq --raw-output ".private_key.value.private_key_pem" tf_output.json >private_key.pem
chmod 0600 private_key.pem

# variables
PUBLIC_IP=$(jq --raw-output ".public_ip.value" tf_output.json)
CERT_EMAIL=${CERT_EMAIL:-$TF_VAR_SERVICE_DESK_EMAIL}
WEBAPP_PORT=${WEBAPP_PORT:-5000}

# database variables
DATABASE_URL=$(jq --raw-output ".database_url.value" tf_output.json)
DATABASE_ENDPOINT=$(jq --raw-output ".database_endpoint.value" tf_output.json)
DATABASE_USERNAME=$(jq --raw-output ".database_username.value" tf_output.json)
DATABASE_PASSWORD=$(jq --raw-output ".database_password.value" tf_output.json)
DATABASE_NAME=$(jq --raw-output ".database_name.value" tf_output.json)

# s3 variables
S3_BUCKET=$(jq --raw-output ".s3_bucket.value" tf_output.json)
S3_BUCKET_DOMAIN=$(jq --raw-output ".s3_bucket_domain.value" tf_output.json)
S3_BUCKET_REGIONAL_DOMAIN=$(jq --raw-output ".s3_bucket_regional_domain.value" tf_output.json)

# smtp variables
SMTP_HOST="email-smtp.$AWS_DEFAULT_REGION.amazonaws.com"
SMTP_USER=$(jq --raw-output ".smtp_user.value" tf_output.json)
SMTP_PASSWORD=$(jq --raw-output ".smtp_password.value" tf_output.json)

# redis variables
REDIS_ADDRESS=$(jq --raw-output ".redis_address.value" tf_output.json)
REDIS_PORT=$(jq --raw-output ".redis_port.value" tf_output.json)
REDIS_AVAILABILITY_ZONE=$(jq --raw-output ".redis_availability_zone.value" tf_output.json)

# extract GL_VARs
printenv | grep GL_VAR_ >gl_vars_demp.txt                                   # get all env vars
sed 's/GL_VAR_//gi' gl_vars_demp.txt >gl_vars_prefix_removed.txt            # strip GL_VAR_ prefix
sed 's/=/="/gi' gl_vars_prefix_removed.txt >gl_vars_quoted_01.txt           # add left quote
sed ':a;N;$!ba;s/\n/"\n/gi' gl_vars_quoted_01.txt >gl_vars_quoted_02.txt    # add right quote
sed ':a;N;$!ba;s/\n/ -e /gi' gl_vars_quoted_02.txt >gl_vars_no_newlines.txt # remove newlines
tr -d '\n' <gl_vars_no_newlines.txt >gl_vars_no_trailing_newline.txt        # remove trailing newline
cp gl_vars_no_trailing_newline.txt gl_vars.txt                              # prepare final gl_vars.txt file
GL_VARs="$(cat gl_vars.txt)"                                                # define GL_VARs
GL_VARs=${GL_VARs:-HELLO=\"WORLD}                                           # handle empty state
GL_VARs=" -e $GL_VARs\""                                                    # wrap between -e and "

# Set Image name. Should be in sync with AutoDevOps build stage naming.
# Taken from https://gitlab.com/gitlab-org/gitlab/-/raw/22f5722e3f39f56b5235b5893d081f022d00fa4c/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml
if [[ -z "$CI_COMMIT_TAG" ]]; then
  export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_SHA}
else
  export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_TAG}
fi

# update package repos
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo apt update
"

if [ $? -ne 0 ]; then
  echo "🟥 Failed to update 'apt' package manager on EC2 instance"
  exit 1
fi

# install and start docker
# log in to gitlab container registry
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo snap install docker
    sudo docker login --username $CI_REGISTRY_USER --password $CI_REGISTRY_PASSWORD $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
"

if [ $? -ne 0 ]; then
  echo "🟥 Failed to install docker or login to container registry on EC2 instance"
  exit 1
fi

# stop and remove all existing containers
# delete all images
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" '
    sudo docker rmi -f $(docker images -a -q)
    sudo docker container stop $(sudo docker container ps -aq) || echo \"No running containers to be stopped\"
    sudo docker container rm $(sudo docker container ps -aq) || echo \"No existing containers to be removed\"
'

if [ $? -ne 0 ]; then
  echo "🟥 Failed to stop or remove containers and container images on EC2 instance"
  exit 1
fi

# pull latest container image
# run container
# DB_INITIALIZE
# DB_MIGRATE
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_APPLICATION_TAG

    sudo docker run --name container_webapp                                 \
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID                             \
        -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY                     \
        -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION                           \
        -e DATABASE_URL=$DATABASE_URL                                       \
        -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                             \
        -e DATABASE_USERNAME=$DATABASE_USERNAME                             \
        -e DATABASE_PASSWORD=$DATABASE_PASSWORD                             \
        -e DATABASE_NAME=$DATABASE_NAME                                     \
        -e S3_BUCKET=$S3_BUCKET                                             \
        -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                               \
        -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN             \
        -e SMTP_HOST=$SMTP_HOST                                             \
        -e SMTP_FROM=$SMTP_FROM                                             \
        -e SMTP_USER=$SMTP_USER                                             \
        -e SMTP_PASSWORD=$SMTP_PASSWORD                                     \
        -e REDIS_ADDRESS=$REDIS_ADDRESS                                     \
        -e REDIS_PORT=$REDIS_PORT                                           \
        -e REDIS_AVAILABILITY_ZONE=$REDIS_AVAILABILITY_ZONE                 \
        $GL_VARs                                                            \
        -d                                                                  \
        -p 8000:$WEBAPP_PORT                                                \
        $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_APPLICATION_TAG

    echo \"DB_INITIALIZE_REPEAT: $DB_INITIALIZE_REPEAT\"
    if [ \"$DB_INITIALIZE_REPEAT\" == \"True\" ]; then
        echo \"DB_INITIALIZE_REPEAT will force repeat execution of DB_INITIALIZE\"
        rm -f DB_INITIALIZE.success
    else
        echo \"DB_INITIALIZE_REPEAT not 'True'\"
    fi

    if [ \"$DB_INITIALIZE\" == \"\" ]; then
        echo \"DB_INITIALIZE is not set\"
    else
        if [ -f DB_INITIALIZE.success ]; then
            echo \"DB_INITIALIZE previously executed and successful\"
        else
            sudo docker exec                                                \
                -e $AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID                    \
                -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY             \
                -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION                   \
                -e DATABASE_URL=$DATABASE_URL                               \
                -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                     \
                -e DATABASE_USERNAME=$DATABASE_USERNAME                     \
                -e DATABASE_PASSWORD=$DATABASE_PASSWORD                     \
                -e DATABASE_NAME=$DATABASE_NAME                             \
                -e S3_BUCKET=$S3_BUCKET                                     \
                -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                       \
                -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN     \
                -e SMTP_HOST=$SMTP_HOST                                     \
                -e SMTP_FROM=$SMTP_FROM                                     \
                -e SMTP_USER=$SMTP_USER                                     \
                -e SMTP_PASSWORD=$SMTP_PASSWORD                             \
                -e REDIS_ADDRESS=$REDIS_ADDRESS                             \
                -e REDIS_PORT=$REDIS_PORT                                   \
                -e REDIS_AVAILABILITY_ZONE=$REDIS_AVAILABILITY_ZONE         \
                $GL_VARs                                                    \
                -i                                                          \
                container_webapp $DB_INITIALIZE
            if [ \$? -eq 0 ]; then
                echo \"DB_INITIALIZE successful\"
                touch DB_INITIALIZE.success
            else
                echo \"🟥 DB_INITIALIZE failed\"
                exit 1
            fi
        fi
    fi

    if [ \"$DB_MIGRATE\" == \"\" ]; then
        echo \"DB_MIGRATE is not set\"
    else
        sudo docker exec                                                    \
            -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID                         \
            -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY                 \
            -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION                       \
            -e DATABASE_URL=$DATABASE_URL                                   \
            -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                         \
            -e DATABASE_USERNAME=$DATABASE_USERNAME                         \
            -e DATABASE_PASSWORD=$DATABASE_PASSWORD                         \
            -e DATABASE_NAME=$DATABASE_NAME                                 \
            -e S3_BUCKET=$S3_BUCKET                                         \
            -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                           \
            -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN         \
            -e SMTP_HOST=$SMTP_HOST                                         \
            -e SMTP_FROM=$SMTP_FROM                                         \
            -e SMTP_USER=$SMTP_USER                                         \
            -e SMTP_PASSWORD=$SMTP_PASSWORD                                 \
            -e REDIS_ADDRESS=$REDIS_ADDRESS                                 \
            -e REDIS_PORT=$REDIS_PORT                                       \
            -e REDIS_AVAILABILITY_ZONE=$REDIS_AVAILABILITY_ZONE             \
            $GL_VARs                                                        \
            -i                                                              \
            container_webapp $DB_MIGRATE
        if [ \$? -eq 0 ]; then
            echo \"DB_MIGRATE successful\"
        else
            echo \"🟥 DB_MIGRATE failed\"
            exit 1
        fi
    fi
"

if [ $? -ne 0 ]; then
  echo "🟥 Failed to start containerized webapp on EC2 instance"
  exit 1
fi

# determine domain
CERT_DOMAIN=${CERT_DOMAIN:-$CI_COMMIT_REF_SLUG.$PUBLIC_IP.resolve.anyip.host}
NGINX_CONF=$(cat conf.nginx)
DYNAMIC_ENVIRONMENT_URL=https://$CERT_DOMAIN

# report dynamic_url
echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >>deploy.env

# install nginx
# delete existing nginx conf (if exists)
# write nginx config
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo apt install nginx -y
    sudo nginx -v
    rm -f conf.nginx
    echo \"$NGINX_CONF\" >conf.nginx
"

if [ $? -ne 0 ]; then
  echo "🟥 Failed to install Nginx or create Nginx configuration on EC2 instance"
  exit 1
fi

# kill running nginx process (if exists)
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo nginx -s stop && echo 'nginx: stopped'
"

if [ $? -ne 0 ]; then
  echo "🟧 Nginx could not be stopped, but that's probably okay. On first run, there's no Nginx instance to stop."
fi

# update package repos
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" "
    sudo snap refresh
    sudo snap install --classic certbot

    sudo certbot certonly                               \
        --non-interactive                               \
        --standalone                                    \
        --agree-tos                                     \
        --email $CERT_EMAIL                             \
        --domains $CERT_DOMAIN                          \
        --cert-name webapp_cert

    sudo chown ubuntu /etc/letsencrypt/live/webapp_cert/fullchain.pem
    sudo chown ubuntu /etc/letsencrypt/live/webapp_cert/privkey.pem
"

if [ $? -ne 0 ]; then
  echo "🟥 Failed to install or execute Certbot on EC2 instance"
  exit 1
fi

# test nginx config
# start nginx process
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$PUBLIC_IP" '
    sudo nginx -t -c ~/conf.nginx
    sudo nginx -c ~/conf.nginx && echo "nginx: started"
'

if [ $? -ne 0 ]; then
  echo "🟥 Failed to start Nginx on EC2 instance"
  exit 1
fi
