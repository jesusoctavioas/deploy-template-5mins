# this script setups certbot
# it is executed by a job named `ssl_certificate`
#
# assumptions:
# - variable CERT_DOMAIN and CERT_EMAIL are defined
# - this is running on protected branch
# - tf files and state are available with valid `public_ip` output in tf_state

gitlab-terraform output -json >tf_output.json
jq --raw-output ".public_ip.value" tf_output.json >public_ip.txt
jq --raw-output ".private_key.value.private_key_pem" tf_output.json >private_key.pem
chmod 0600 private_key.pem

# update package repos
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$(cat public_ip.txt)" "
    sudo snap refresh
    sudo snap install --classic certbot

    sudo nginx -s stop && echo 'nginx: stopped'

    sudo certbot certonly                               \
        --non-interactive                               \
        --standalone                                    \
        --agree-tos                                     \
        --email $CERT_EMAIL                             \
        --domains $CERT_DOMAIN                          \
        --cert-name webapp_cert

    sudo chown ubuntu /etc/letsencrypt/live/webapp_cert/fullchain.pem
    sudo chown ubuntu /etc/letsencrypt/live/webapp_cert/privkey.pem

    sudo nginx -c ~/conf.nginx && echo 'nginx: started'
"

if [ $? -ne 0 ]; then
    exit 1
fi
