#!/usr/bin/python3

import os, sys, json, subprocess

terraform_location_env = os.environ.get('TF_STATE', False)

if terraform_location_env != False and len(sys.argv) > 1 and sys.argv[1] == '--list':
    tf_state_pull_output = subprocess.run(["terraform", "state", "pull"], capture_output=True , cwd=terraform_location_env)
    terraform_state_json = json.loads(tf_state_pull_output.stdout)
    inventory_json = {"all": {"children": ["app", "db", "localhost1"]}, "localhost1": {"hosts": ["localhost"]},"app": {"hosts": ["appserver"]}, "db": {"hosts": ["dbserver"]}, "_meta": {"hostvars": {"appserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_app"]["value"], "db_host": terraform_state_json["outputs"]["internal_ip_address_db"]["value"]}, "dbserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_db"]["value"]}, "localhost":{"ansible_host": "127.0.0.1" }}}}

    #write json to file
    file = open("inventory.json","w")
    file.write(json.dumps(inventory_json, indent=4))
    file.close()

    #print to stdout for ansible
    print(json.dumps(inventory_json, indent=4))
