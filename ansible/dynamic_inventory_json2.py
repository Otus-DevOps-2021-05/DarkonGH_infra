#!/usr/bin/python3

import os, sys, json, subprocess, time

my_env=os.environ

try:
    with open('env_tf_state.env','r') as env_file:
        env = env_file.read().replace('\n','')
    if os.stat('env_tf_state.env').st_size > 1:
        my_env['TF_STATE']=env
except FileNotFoundError:
    #print ('Файл env_tf_state.env не обнаружен в рабочей директории, использую переменную окружения TF_STATE')
    time.sleep(3)
finally:
    terraform_location_env = os.environ.get('TF_STATE', False)
    if terraform_location_env == False:
        print ('переменная окружения TF_STATE не задана, завершение работы скрипта')
    #else:
        #subprocess.run("clear")

if terraform_location_env != False and len(sys.argv) > 1 and sys.argv[1] == '--list':
    tf_state_pull_output = subprocess.run(["terraform", "state", "pull"], capture_output=True , cwd=terraform_location_env)
    terraform_state_json = json.loads(tf_state_pull_output.stdout)
    inventory_json = {"all": {"children": ["app", "db"]}, "app": {"hosts": ["appserver"]}, "db": {"hosts": ["dbserver"]}, "_meta": {"hostvars": {"appserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_app"]["value"], "db_host": terraform_state_json["outputs"]["internal_ip_address_db"]["value"]}, "dbserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_db"]["value"]}, "localhost":{"ansible_host": "127.0.0.1" }}}}

    #write json to file
    file = open("inventory.json","w")
    file.write(json.dumps(inventory_json, indent=4))
    file.close()

    db_host_json={"db_host": terraform_state_json["outputs"]["internal_ip_address_db"]["value"]}

    #write vars to ansible
    file = open("vars.json","w")
    #file.write('db_host: ' + db_host)
    file.write(json.dumps(db_host_json, indent=4))
    file.close()

    #print to stdout for ansible
    print(json.dumps(inventory_json, indent=4))
