# extract terraform state
gitlab-terraform output -json >tf_output.json
jq --raw-output ".public_ip.value" tf_output.json >public_ip.txt
jq --raw-output ".private_key.value.private_key_pem" tf_output.json >private_key.pem
jq --raw-output ".database_url.value" tf_output.json >database_url.txt
jq --raw-output ".database_endpoint.value" tf_output.json >database_endpoint.txt
jq --raw-output ".database_username.value" tf_output.json >database_username.txt
jq --raw-output ".database_password.value" tf_output.json >database_password.txt
jq --raw-output ".database_name.value" tf_output.json >database_name.txt
jq --raw-output ".s3_bucket.value" tf_output.json >s3_bucket.txt
jq --raw-output ".s3_bucket_domain.value" tf_output.json >s3_bucket_domain.txt
jq --raw-output ".s3_bucket_regional_domain.value" tf_output.json >s3_bucket_regional_domain.txt
chmod 0600 private_key.pem

# set dynamic url
DYNAMIC_ENVIRONMENT_URL=$(cat public_ip.txt)
echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >>deploy.env

# variables
WEBAPP_PORT=${WEBAPP_PORT:-5000}
DATABASE_URL=$(cat database_url.txt)
DATABASE_ENDPOINT=$(cat database_endpoint.txt)
DATABASE_USERNAME=$(cat database_username.txt)
DATABASE_PASSWORD=$(cat database_password.txt)
DATABASE_NAME=$(cat database_name.txt)
S3_BUCKET=$(cat s3_bucket.txt)
S3_BUCKET_DOMAIN=$(cat s3_bucket_domain.txt)
S3_BUCKET_REGIONAL_DOMAIN=$(cat s3_bucket_regional_domain.txt)
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
echo "$GL_VARs"

# Set Image name. Should be in sync with AutoDevOps build stage naming.
# Taken from https://gitlab.com/gitlab-org/gitlab/-/raw/22f5722e3f39f56b5235b5893d081f022d00fa4c/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml
if [[ -z "$CI_COMMIT_TAG" ]]; then
    export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG}
    export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_SHA}
else
    export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE}
    export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_TAG}
fi

# execute on EC2 instance
# install and start docker
# log in to gitlab container registry
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ec2-user@"$(cat public_ip.txt)" "
    sudo amazon-linux-extras install docker
    sudo service docker start

    sudo docker login --username $CI_REGISTRY_USER --password $CI_REGISTRY_PASSWORD $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
 "

# stop and remove all existing containers
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ec2-user@"$(cat public_ip.txt)" '
    sudo docker container stop $(sudo docker container ps -aq) || echo \"No running containers to be stopped\"
    sudo docker container rm $(sudo docker container ps -aq) || echo \"No existing containers to be removed\"
'

# pull latest container image
# run container
# DB_INITIALIZE
# DB_MIGRATE
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ec2-user@"$(cat public_ip.txt)" "
    sudo docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_APPLICATION_TAG

    sudo docker run --name container_webapp                                 \
        -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY                                   \
        -e AWS_SECRET_KEY=$AWS_SECRET_KEY                                   \
        -e AWS_REGION=$AWS_REGION                                           \
        -e DATABASE_URL=$DATABASE_URL                                       \
        -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                             \
        -e DATABASE_USERNAME=$DATABASE_USERNAME                             \
        -e DATABASE_PASSWORD=$DATABASE_PASSWORD                             \
        -e DATABASE_NAME=$DATABASE_NAME                                     \
        -e S3_BUCKET=$S3_BUCKET                                             \
        -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                               \
        $GL_VARs                                                            \
        -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN             \
        -d                                                                  \
        -p 8000:$WEBAPP_PORT                                                  \
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
                -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY                           \
                -e AWS_SECRET_KEY=$AWS_SECRET_KEY                           \
                -e AWS_REGION=$AWS_REGION                                   \
                -e DATABASE_URL=$DATABASE_URL                               \
                -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                     \
                -e DATABASE_USERNAME=$DATABASE_USERNAME                     \
                -e DATABASE_PASSWORD=$DATABASE_PASSWORD                     \
                -e DATABASE_NAME=$DATABASE_NAME                             \
                -e S3_BUCKET=$S3_BUCKET                                     \
                -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                       \
                -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN     \
                $GL_VARs                                                    \
                -i                                                          \
                container_webapp $DB_INITIALIZE
            if [ \$? -eq 0 ]; then
                echo \"DB_INITIALIZE successful\"
                touch DB_INITIALIZE.success
            else
                echo \"DB_INITIALIZE failed\"
                exit 1
            fi
        fi
    fi

    if [ \"$DB_MIGRATE\" == \"\" ]; then
        echo \"DB_MIGRATE is not set\"
    else
        sudo docker exec                                                    \
            -e AWS_ACCESS_KEY=$AWS_ACCESS_KEY                               \
            -e AWS_SECRET_KEY=$AWS_SECRET_KEY                               \
            -e AWS_REGION=$AWS_REGION                                       \
            -e DATABASE_URL=$DATABASE_URL                                   \
            -e DATABASE_ENDPOINT=$DATABASE_ENDPOINT                         \
            -e DATABASE_USERNAME=$DATABASE_USERNAME                         \
            -e DATABASE_PASSWORD=$DATABASE_PASSWORD                         \
            -e DATABASE_NAME=$DATABASE_NAME                                 \
            -e S3_BUCKET=$S3_BUCKET                                         \
            -e S3_BUCKET_DOMAIN=$S3_BUCKET_DOMAIN                           \
            -e S3_BUCKET_REGIONAL_DOMAIN=$S3_BUCKET_REGIONAL_DOMAIN         \
            $GL_VARs                                                        \
            -i                                                              \
            container_webapp $DB_MIGRATE
        if [ \$? -eq 0 ]; then
            echo \"DB_MIGRATE successful\"
        else
            echo \"DB_MIGRATE failed\"
            exit 1
        fi
    fi
"

# kill running nginx process (if exists)
# delete existing nginx conf (if exists)
# write nginx config
# start nginx process
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ec2-user@"$(cat public_ip.txt)" "
sudo yum install nginx -y
sudo nginx -v
rm -f conf.nginx
echo \"$(cat conf.nginx)\" >conf.nginx
ls -al
cat conf.nginx
"
