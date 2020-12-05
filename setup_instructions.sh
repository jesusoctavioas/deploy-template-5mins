# this script provides DNS setup instructions
# it is executed by a job named `setup_instructions`
#
# assumptions:
# - variable DOMAIN is defined
# - this is running on protected branch
# - tf files and state are available with valid `public_ip` output in tf_state

