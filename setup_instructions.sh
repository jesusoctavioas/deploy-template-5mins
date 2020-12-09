# this script provides DNS setup instructions
# it is executed by a job named `setup_instructions`
#
# assumptions:
# - variable CERT_DOMAIN and CERT_EMAIL are defined
# - this is running on protected branch
# - tf files and state are available with valid `public_ip` output in tf_state

gitlab-terraform output -json >tf_output.json
jq --raw-output ".public_ip.value" tf_output.json >public_ip.txt

echo ""
echo "DNS SETUP INSTRUCTIONS"
echo "======================"
echo ""
echo "1. Create an A record and point it to $(cat public_ip.txt)"
echo "2. Execute ssl_certificate job"
echo ""
