#!/usr/bin/python3

import os, sys, json, subprocess, time, datetime

my_env=os.environ

# логирование
file_log =open("work.log","a")
file_log.write("\n" + str (datetime.datetime.now()) + " Запуск \n")

terraform_location_env = os.environ.get("TF_STATE", False)

if terraform_location_env == False:
    file_log.write(str(datetime.datetime.now()) + " Переменная окружения TF_STATE не задана, читаем путь к terraform state из файла env_tf_state.env" + "\n")
    try:
        with open("env_tf_state.env","r") as env_file:
            env = env_file.read().replace("\n","")
            file_log.write(str (datetime.datetime.now()) + " Содержимое файла env_tf_state.env прочитано: " + env + "\n")
        if os.stat("env_tf_state.env").st_size > 1:
            my_env["TF_STATE"]=env
            terraform_location_env = os.environ.get("TF_STATE", False)
            file_log.write(str (datetime.datetime.now()) + " переменной окружения TF_STATE присвоено значение " + str(terraform_location_env) + "\n")
    except FileNotFoundError:
        file_log.write(str(datetime.datetime.now()) + " Файл env_tf_state.env не обнаружен в рабочей директории, завершаем работу" + "\n")
        time.sleep(3)

file_log.close

if terraform_location_env != False and len(sys.argv) > 1 and sys.argv[1] == '--list':
    tf_state_pull_output = subprocess.run(["terraform", "state", "pull"], capture_output=True , cwd=terraform_location_env)
    terraform_state_json = json.loads(tf_state_pull_output.stdout)
    inventory_json = {"all": {"children": ["app", "db"]}, "app": {"hosts": ["appserver"]}, "db": {"hosts": ["dbserver"]}, "_meta": {"hostvars": {"appserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_app"]["value"], "db_host": terraform_state_json["outputs"]["internal_ip_address_db"]["value"]}, "dbserver": {"ansible_host": terraform_state_json["outputs"]["external_ip_address_db"]["value"]}}}}

    #write json to file
    file = open("inventory.json","w")
    file.write(json.dumps(inventory_json, indent=4))
    file.close()

    #print to stdout for ansible
    print(json.dumps(inventory_json, indent=4))
