# extract terraform state
gitlab-terraform output -json >tf_output.json
jq --raw-output ".public_ip.value" tf_output.json >public_ip.txt
jq --raw-output ".private_key.value.private_key_pem" tf_output.json >private_key.pem
jq --raw-output ".database_url.value" tf_output.json >database_url.txt
chmod 0600 private_key.pem

# set dynamic url
DYNAMIC_ENVIRONMENT_URL=$(cat public_ip.txt)
echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >>deploy.env

# execute on EC2 instance
# install and start docker
# log in to gitlab container registry
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ec2-user@"$(cat public_ip.txt)" "
    sudo amazon-linux-extras install docker
    sudo service docker start

    sudo docker login --username $CI_REGISTRY_USER --password $CI_REGISTRY_PASSWORD $CI_REGISTRY_IMAGE
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
    sudo docker pull $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

    sudo docker run --name container_webapp -e DATABASE_URL=$(cat database_url.txt) -d -p 80:${WEBAPP_PORT:-5000} $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

    if [ -z ${DB_INITIALIZE+x} ]; then
        echo \"DB_INITIALIZE is not set\"
    else
        if [ -f DB_INITIALIZE.success ]; then
            echo \"DB_INITIALIZE previously executed and successful\"
        else
            sudo docker exec -e DATABASE_URL=$(cat database_url.txt) -i container_webapp $DB_INITIALIZE
            if [ $? -eq 0 ]; then
                echo \"DB_INITIALIZE successful\"
                touch DB_INITIALIZE.success
            else
                echo \"DB_INITIALIZE failed\"
            fi
        fi
    fi

    if [ -z ${DB_MIGRATE+x} ]; then
        echo \"DB_MIGRATE is not set\"
    else
        sudo docker exec -e DATABASE_URL=$(cat database_url.txt) -i container_webapp $DB_MIGRATE
        if [ $? -eq 0 ]; then
            echo \"DB_MIGRATE successful\"
        else
            echo \"DB_MIGRATE failed\"
        fi
    fi
"
