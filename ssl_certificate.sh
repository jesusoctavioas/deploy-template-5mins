# this script setups certbot
# it is executed by a job named `ssl_certificate`
#
# assumptions:
# - variable DOMAIN is defined
# - this is running on protected branch
# - tf files and state are available with valid `public_ip` output in tf_state

