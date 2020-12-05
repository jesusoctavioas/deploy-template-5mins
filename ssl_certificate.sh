# this script setups certbot
# it is executed by a job named `ssl_certificate`
#
# assumptions:
# - variable CERT_DOMAINS and CERT_EMAIL are defined
# - this is running on protected branch
# - tf files and state are available with valid `public_ip` output in tf_state

gitlab-terraform output -json >tf_output.json
jq --raw-output ".public_ip.value" tf_output.json >public_ip.txt
jq --raw-output ".private_key.value.private_key_pem" tf_output.json >private_key.pem

# update package repos
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i private_key.pem ubuntu@"$(cat public_ip.txt)" "
    sudo snap refresh
    sudo snap install --classic certbot
    sudo certbot --nginx --agree-tos --email $CERT_EMAIL --domains $CERT_DOMAINS --non-interactive
"

if [ $? -ne 0 ]; then
    exit 1
fi
