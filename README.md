# DarkonGH_infra

DarkonGH Infra repository

Блок проверки ДЗ:

bastion_IP = 178.154.231.92
someinternalhost_IP = 10.128.0.12

testapp_IP = 178.154.240.105
testapp_port = 9292

## Домашнее задание №3 *Знакомство с облачной инфраструктурой. Yandex.Cloud*

### Самостоятельное задание 1 ssh

#### Добавление приватного ключа в ssh-agent локальной машины

Выполняется командой *ssh-add C:\Users\darkon\.ssh\appuser*
предварительно необходимо запустить службу *OpenSSH Authentication Agent*

#### Подключение на машину *bastion*

```
PS C:\WINDOWS\system32> ssh -A appuser@217.28.231.251
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@bastion:~$
```

#### Настройка OpenSSH сервера

Внесем параметры, необходимые для перенаправления подключения, в конфигурационный файл **/etc/ssh/sshd_config**:
*AllowTcpForwarding yes*
*GatewayPorts yes*
Перезапустим OpenSSH сервис командой *sudo systemctl restart sshd*.

#### Настройка перенаправления подключения на VM *bastion*

На машине *bastion* настроим перенаправление подключения с локального порта 22022 на машину someinternalhost с IP 10.128.0.12, порт 22, командой:
*appuser@bastion:~$ ssh -fN -L 22022:localhost:22 10.128.0.12*

Для проверки подключения введем команду *ssh appuser@localhost -p 22022*

```
appuser@bastion:~$ ssh appuser@localhost -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@someinternalhost:~$
```

Судя по приглашению *appuser@someinternalhost* подключение прошло успешно.

#### Подключимся с локального рабочего устройства в одну команду

*ssh -A appuser@178.154.231.92 -p 22022*
где IP адрес 178.154.231.92 машины *bastion*

```
PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 -p 22022
ssh: connect to host 178.154.231.92 port 22022: Connection refused
```

Подключение должно было пройти напрямую на машину *someinternalhost*, но возникла ошибка.
По каким то причинам порт 22022 блокируется.
Просмотр iptables на машине *bastion* показывает, что все порты открыты (применена политика ACCEPT):

```
appuser@bastion:~$ sudo iptables -L -nv
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

Изучение документации Yandex Cloud не дает ответа какие порты блокируются и блокируются ли вообще:
<https://cloud.yandex.ru/docs/vpc/concepts/network>
>Для виртуальных машин Yandex Compute Cloud и хостов баз данных доступ из интернета и в интернет открыт через публичные IP-адреса.

Вывод: Недостаточно информации для завершения задания
Вывод2: Судя по локальному IP адресу *Bastion* VM находится за NAT, хотя и имеет публичный IP адрес в Yandex Cloud (YC).
В таком случае требуется настроить Port Forwarding, настроек которого в YC не обнаружил.

#### Проверка добавления внешнего IP адреса в команду перенаправления

По совету преподавателя, добавим явное указание локального IP адреса с которого получать подключение, ключ *-D внешний IP:порт*.
Но что-то тут не то, т.к. при запуске пишется перенаправление:
debug1: Local connections to 10.128.0.13:22022 forwarded to remote address socks:0
Данный ключ не подходит.

Пересоздадим *bastion* VM, т.к. был утрачен доступ из-за ошибки внесенной в sshd_config.
Как выяснилось, при повторной настройке, я ранее внес команду *GatewayPorts yes* не в тот конфиг файл,
надо вносить в **ssh_config**. После этого команда: *ssh -fNv -L 22022:localhost:22 10.128.0.12* запустилась на всех интерфейсах

```
debug1: Authentication succeeded (publickey).
Authenticated to 10.128.0.12 ([10.128.0.12]:22).
debug1: Local connections to *:22022 forwarded to remote address localhost:22
debug1: Local forwarding listening on 0.0.0.0 port 22022.
debug1: channel 0: new [port listener]
debug1: Local forwarding listening on :: port 22022.
```

Далее, подключаемся с локальной  рабочей машины, командой *ssh -A appuser@178.154.231.92 -p 22022* напрямую к someinternalhost, минуя bastion VM:

```
PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@someinternalhost:~$ hostname
someinternalhost
appuser@someinternalhost:~$ uname -a
Linux someinternalhost 4.4.0-142-generic #168-Ubuntu SMP Wed Jan 16 21:00:45 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
appuser@someinternalhost:~$
```

Бонусом:
Выполняем еще одно перенаправление с локальной рабочей машины:
*PS C:\WINDOWS\system32> ssh  -fNv -A appuser@178.154.231.92 -L 22022:localhost:22022 178.154.231.92*
После этого можно подключаться локально на localhost:22022, попадая сразу на someinternalhost:

```
PS C:\WINDOWS\system32> ssh -A appuser@localhost -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@someinternalhost:~$ hostname
someinternalhost
appuser@someinternalhost:~$
```

#### еще один вариант подключения одной командой

Введем команду *ssh -A appuser@178.154.231.92 ssh 10.128.0.12*.

```
PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 ssh 10.128.0.12
Pseudo-terminal will not be allocated because stdin is not a terminal.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
hostname
someinternalhost
uname -a
Linux someinternalhost 4.4.0-142-generic #168-Ubuntu SMP Wed Jan 16 21:00:45 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
```

### Дополнительное задание 1 ssh

Настройка алиаса someinternalhost

Создадим файл *~/.ssh/config*
Добавим параметры удаленного хоста:

```
Host someinternalhost
HostName 127.0.0.1
User appuser
Port 22022
```

Теперь можно подключаться к удаленному серверу по алиасу:
*ssh someinternalhost*

```
PS C:\WINDOWS\system32> ssh someinternalhost
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@someinternalhost:~$
```

Подключение прошло успешно.

### Установка VPN-сервера для серверов Yandex.Cloud

Установка vpn будет производится на Ubuntu 18.04.5 LTS, для этого внесем изменения в скрипт **/vpn-bastion/setupvpn.sh**.
Для внесения изменений в первоначальный скрипт использовалась статья <https://www.howtoforge.com/how-to-setup-a-vpn-server-using-pritunl-on-ubuntu-1804/>

После настройки vpn и подключения, проверяем подключение к someinternalhost с 10.128.0.12

```
PS C:\WINDOWS\system32> ssh -A appuser@10.128.0.12
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  <https://help.ubuntu.com>
 * Management:     <https://landscape.canonical.com>
 * Support:        <https://ubuntu.com/advantage>
appuser@someinternalhost:~$
```

### Подключение к bastion и someinternalhost

    bastion_IP = 178.154.231.92
    someinternalhost_IP = 10.128.0.12

### Дополнительное задание 2 VPN с сертификатом

Для создания подписанного сертификата при помощи сервиса Let's Encrypt используем доменное имя на основе IP адреса, сервиса sslip.io:
*178-154-231-92.sslip.io*
Далее производим настройку certbot согласно инструкции <https://certbot.eff.org/lets-encrypt/ubuntubionic-other>
После настройки certbot проверяем, что у нас работает безопасное подключение в браузере <https://178-154-231-92.sslip.io/#>

В настройках pritunl vpn сервера указываем Lets Encrypt Domain: *178-154-231-92.sslip.io*

## Домашнее задание №4 Деплой тестового приложения

### параметры для автоматической проверки домашнего задания

    testapp_IP = 178.154.240.105
    testapp_port = 9292

### Создание новой ветки cloud-testapp

выполним команду *git checkout -b cloud-testapp*

### Изучение написания Bash скриптов

Полезная статья для понимания bash скриптов <https://habr.com/en/company/ruvds/blog/325522/>

### Добавление скрипта деплоя приложения после создания инстанса

Дополнительный ключ *--metadata-from-file user-data=metadata.yaml*, который позволяет выполнять необходимые действия после создания инстанса.

```
 yc compute instance create \
 --name reddit-app \
 --hostname reddit-app \
 --memory=4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
 --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
 --metadata-from-file user-data=metadata.yaml \
 --metadata serial-port-enable=1
```

## Домашнее задание №5  Сборка образов VM при помощи Packer

### Основное ДЗ Сборка образов VM при помощи Packer

### Задание со * Построение Bake образа

В процессе сделано:

* Создан сервисный аккаунт для Packer в Yandex Cloud и делегированы права.
* Создание шаблона для Packer и его настройка (секции билдера и провиженеров)
* Собран образ с предустановленными ruby и mongodb
* Проверка загрузки ВМ из созданного образа. Проверка установки приложения
* Параметризация шаблона, перенос чувствительных данных в переменные variables.json

### Запуск сборки immunable образа

    packer build -var-file=./variables.json ./immutable.json

## Домашнее задание №6 Практика IaC с использованием Terraform

### Основное ДЗ Изучение Terraform и создание VM

* Настройка конфигурационных файлов Terraform и отработка создание VM.
* Работа с Provisioners - деплой тестового приложения.
* Вынос переменных в Inputs vars

### Самостоятельные задания

* Определим переменную для приватного ключа использующегося в определении подключения для
провиженеров (connection).

```
variable "private_key_path" {
   description = "Path to the private ssh key"
 }

private_key_path         = "~/.ssh/ubuntu"
```

* Определим input переменную для зоны в ресурсе "yandex_compute_instance" "app" и ее значение по умолчанию.
```
variable "zone" {
   description = "Zone"
   # Значение по умолчанию
   default = "ru-central1-a"
}
```

* Создание файла *terraform.tfvars.example* примера в переменными.

### Задание со звездочками

* Настройка балансировщика в Yandex Cloud. Конфигурационный файл lb.tf. При обращении к адресу балансировщика должно открываться задеплоенное приложение.
* Добавление второго инстанса в *main.tf*
* Добавим вывод IP Адреса балансировщика в output переменную:

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "178.154.207.150"
external_ip_address_app1 = "178.154.220.113"
lb_ip_address = tolist([
 "84.201.134.115",
])
```

* Проблемы конфигурации деплоя приложения на два инстанса - т.к. у нас в развертываемом приложении используется база данных MongoDB на каждом инстансе, то получается должно быть настроено зеркалирование или репликация данных между БД, для корректной работы приложения с балансировщиком. А также присутствует избыточная конфигурация в коде.

* Описание создания идентичных инстансов через параметр count, в *main.tf* добавим:

```
resource "yandex_compute_instance" "app" {
name  = "reddit-app-${count.index}"
count = var.count_of_instances
```

в *variables.tf* добавим:

```
variable count_of_instances {
description = "Count of instances"
default     = 2
}
```

в *lb.tf* добавим:

```
resource "yandex_lb_target_group" "app_lb_target_group" {
name      = "app-lb-group"
region_id = var.region_id

    dynamic "target" {
      for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
      content {
          subnet_id = var.subnet_id
          address   = target.value
        }
    }
  }
```

 в *outputs.tf* добавим:
```
  output "external_ip_address_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
 }
```

### Полезные ссылки для настройки

-[The count Meta-Argument](<https://www.terraform.io/docs/language/meta-arguments/count.html>)
-[The for_each Meta-Argument](<https://www.terraform.io/docs/language/meta-arguments/for_each.html>)
-[dynamic Blocks](<https://www.terraform.io/docs/language/expressions/dynamic-blocks.html>)
-[yandex_lb_network_load_balancer](<https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer>)
-[yandex_lb_target_group](<https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group>)

Команды просмотра балансировщика нагрузки в YC:

```
yc load-balancer network-load-balancer list
yc load-balancer target-group list
```

## Домашнее задание №7 Создание Terraform модулей для управления компонентами инфраструктуры

### Создание ресурса IP адрес и пример неявной зависимости

добавим в *main.tf* следующую конфигурацию:

```
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```

ссылаемся на атрибуты ресурса создания IP адреса в конфигурации истанса:

```
network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }
```

Неявная зависимость видна при создании инстанса, terraform apply, сначала создаются ресурсы сети и только потом создается VM:

```
yandex_vpc_network.app-network: Creating...
yandex_vpc_network.app-network: Creation complete after 1s [id=enp0g0avvho9sa9h86ve]
yandex_vpc_subnet.app-subnet: Creating...
yandex_vpc_subnet.app-subnet: Creation complete after 1s [id=e9br8q7coki7id5s3l36]
yandex_compute_instance.app[0]: Creating...
yandex_compute_instance.app[0]: Still creating... [10s elapsed]
yandex_compute_instance.app[0]: Still creating... [20s elapsed]
yandex_compute_instance.app[0]: Still creating... [30s elapsed]
yandex_compute_instance.app[0]: Still creating... [40s elapsed]
yandex_compute_instance.app[0]: Creation complete after 44s [id=fhmj5vmmjdosu765s8lk]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = [
  "84.252.128.11",
]
```

### Структуризация ресурсов

#### Подготовка образов диска Packer'ом

Вынесем БД на отдельный инстанс VM, подготовим конфигурационный файл *db.json* пакера и сформируем образ с предустановленной БД:

```
 packer validate -var-file=./variables.json ./db.json
 packer build -var-file=./variables.json ./db.json
 ```
 результат сборки образа db:

```
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-db-base-1627600848 (id: fd8f4juab4fmv5p1jbgt) with family name reddit-db-base
```

Подготовим аналогично шаблон *app.json* для отдельного инстанса VM с предустановленным Ruby

```
 packer validate -var-file=./variables.json ./app.json
 packer build -var-file=./variables.json ./app.json
 ```

результат сборки образа app:

```
==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1627600255 (id: fd85f5u0km4cen9qncrm) with family name reddit-app-base
```

#### Разнесение конфигурации Терраформа на две VM

Подготовим конфиги *app.tf* и *bd.tf* на основе конфига *main.tf* из предыдущего ДЗ. Создание ресурса сети вынесем в отдельный конфиг *vpc.tf*

Примем изменения - terraform apply, и соберем VM:

```
yandex_vpc_network.app-network: Creating...
yandex_vpc_network.app-network: Creation complete after 1s [id=enpanp36tns7g84o67lq]
yandex_vpc_subnet.app-subnet: Creating...
yandex_vpc_subnet.app-subnet: Creation complete after 1s [id=e9bpouiaf1ns5gupl466]
yandex_compute_instance.db: Creating...
yandex_compute_instance.app: Creating...
yandex_compute_instance.db: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.db: Still creating... [20s elapsed]
yandex_compute_instance.app: Still creating... [20s elapsed]
yandex_compute_instance.db: Still creating... [30s elapsed]
yandex_compute_instance.app: Still creating... [30s elapsed]
yandex_compute_instance.db: Still creating... [40s elapsed]
yandex_compute_instance.app: Still creating... [40s elapsed]
yandex_compute_instance.db: Creation complete after 45s [id=fhmcsgp9mu64gq50458j]
yandex_compute_instance.app: Creation complete after 47s [id=fhmg9v381og3d7l1flj4]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "178.154.223.73"
external_ip_address_db = "178.154.221.174"
```

Проверим, что хост app доступен и на нем установлено Ruby:

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ ssh ubuntu@178.154.223.73
The authenticity of host '178.154.223.73 (178.154.223.73)' can't be established.
ECDSA key fingerprint is SHA256:9rhZs8SDsnqCvZ38E+AtghDDX8CRs5afod6UWPwXSvg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '178.154.223.73' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
ubuntu@fhmg9v381og3d7l1flj4:~$ ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
ubuntu@fhmg9v381og3d7l1flj4:~$
```

Проверим, что хост db доступен и на нем установлено MongoDb:

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ ssh ubuntu@178.154.221.174
The authenticity of host '178.154.221.174 (178.154.221.174)' can't be established.
ECDSA key fingerprint is SHA256:xo5ls/ERG7DssPNezKl+QAPZOoApSFkpW2rG9EfVxUo.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '178.154.221.174' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

ubuntu@fhmcsgp9mu64gq50458j:~$ systemctl status mongod
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2021-07-30 06:55:38 UTC; 6min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 639 (mongod)
   CGroup: /system.slice/mongod.service
           └─639 /usr/bin/mongod --config /etc/mongod.conf

Jul 30 06:55:38 fhmcsgp9mu64gq50458j systemd[1]: Started MongoDB Database Server.
```

### Модули

Создадим модули app и db на основе написанной ранее конфигурации.

Для использования модулем загрузим их из указанного источника *source* (в нашем случае локальная папка).
Выполним команду для загрузки модулей:

```
terraform get
```

Модули будут загружены в директорию .terraform, в которой уже содержится провайдер Yandex Cloud.

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ tree .terraform
.terraform
├── modules
│   └── modules.json
└── providers
    └── registry.terraform.io
        └── yandex-cloud
            └── yandex
                └── 0.61.0
                    └── linux_amd64
                        ├── CHANGELOG.md
                        ├── LICENSE
                        ├── README.md
                        └── terraform-provider-yandex_v0.61.0

7 directories, 5 files
```

Результат сборки новых VM на основе модулей:

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ terraform apply

  Enter a value: yes

module.app.yandex_compute_instance.app: Creating...
module.db.yandex_compute_instance.db: Creating...
module.app.yandex_compute_instance.app: Still creating... [10s elapsed]
module.db.yandex_compute_instance.db: Still creating... [10s elapsed]
module.app.yandex_compute_instance.app: Still creating... [20s elapsed]
module.db.yandex_compute_instance.db: Still creating... [20s elapsed]
module.app.yandex_compute_instance.app: Still creating... [30s elapsed]
module.db.yandex_compute_instance.db: Still creating... [30s elapsed]
module.app.yandex_compute_instance.app: Still creating... [40s elapsed]
module.db.yandex_compute_instance.db: Still creating... [40s elapsed]
module.db.yandex_compute_instance.db: Creation complete after 41s [id=fhmq47f04vt84pbkot1r]
module.app.yandex_compute_instance.app: Creation complete after 46s [id=fhm9ks51orjvr9mqb1ol]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "178.154.223.61"
external_ip_address_db = "84.252.130.19184.252.130.191"
```

Проверка наличия Ruby на VM app:

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ ssh ubuntu@178.154.223.61
The authenticity of host '178.154.223.61 (178.154.223.61)' can't be established.
ECDSA key fingerprint is SHA256:fCQImPKwUaE+rPfKwWt+64SdIokjWwqWBNLBpxWwh44.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '178.154.223.61' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
ubuntu@fhm9ks51orjvr9mqb1ol:~$ ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
```

Проверка наличия MongoDB на VM db

```
darkon@darkonVM:~/DarkonGH_infra/terraform (terraform-2)$ ssh ubuntu@84.252.130.191
The authenticity of host '84.252.130.191 (84.252.130.191)' can't be established.
ECDSA key fingerprint is SHA256:EQL++K86AMLBlhrDEazk29FdezBDmgkgHcdYBQAsx6g.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '84.252.130.191' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
ubuntu@fhmq47f04vt84pbkot1r:~$ systemctl status mongod
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2021-07-30 15:20:13 UTC; 5min ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 654 (mongod)
   CGroup: /system.slice/mongod.service
           └─654 /usr/bin/mongod --config /etc/mongod.conf

Jul 30 15:20:13 fhmq47f04vt84pbkot1r systemd[1]: Started MongoDB Database Server.
```

### Переиспользование модулей

Создадим конфигурацию stage и prod с учетом использования общих модулей, принцип DRY (Don't repeat youself).
Скопируем файлы: *key_tf.json  main.tf  outputs.tf terraform.tfvars  terraform.tfvars.example  variables.tf*  из папки terraform/ в
terraform/stage и инициализируем terraform в каждой папке:

```
darkon@darkonVM:~/DarkonGH_infra/terraform/stage (terraform-2)$ terraform init
Initializing modules...
- app in ../modules/app
- db in ../modules/db

Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.61.0...
- Installed yandex-cloud/yandex v0.61.0 (self-signed, key ID E40F590B50BB8E40)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Повторим тоже самое для prod.

Проверим сборку VM для stage и prod - terraform apply, и удаление terraform destroy.

### Самостоятельное задание

Параметризуем конфигурацию модулей, вынесем в переменные значения cores, core_fraction, memory и имя VM

### Задание со *

#### Настройка и хранение стейт файлов на удаленном бэкенде (Yandex Object Storage) для stage и prod

Для настройки воспользуемся [инструкцией](<https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-state-storage>)

Создадим s3 бакет - terraform-yc-s3, с правами на чтение и запись, для сервисного аккаунта.

Конфигурация бэкенда задается в секции terraform, backend "s3":

```
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-yc-s3"
    region     = "ru-central1"
    key        = "stage/terraform.tfstate"
    access_key = var.access_key
    secret_key = var.secret_key

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```

Секретные ключи вынесем в отдельный файл *backend-config* с переменными, так называемой ["Partial Configuration"](<https://www.terraform.io/docs/language/settings/backends/configuration.html#partial-configuration>), по структуре аналогичный terraform.tfvars.


Выполним terraform init или terraform init -reconfigure с указанием ключа backend-config=./backend-config:

```
terraform init -reconfigure -backend-config=./backend-config

Initializing modules...

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.61.0

Terraform has been successfully initialized!
```

Добавим файл  *backend-config* в .gitignore, для исключения попадания чувствительных данных в git.

#### Перенос конфигурационных файлов Terraform в другую директорию, проверка работы стейт файла из бэкета

После настройки поддержки S3 бэкенда терраформ видит стейт файл из облака независимо от запускаемой директории.

#### Одновременный запуск применения конфигурации

В ходе тестов с Yandex Cloud выяснилось, что блокировка применения конфигурации не работает. Т.к. нет поддержки DynamoDb.
Для примера в AWS S3 необходимо создать dyanamodb_table в существующей DaynamoDB, после этого включится блокировка удаленного стейт файла.

```
Stores the state as a given key in a given bucket on Amazon S3. This backend also supports state locking and consistency checking via Dynamo DB, which can be enabled by setting the dynamodb_table field to an existing DynamoDB table name. A single DynamoDB table can be used to lock multiple remote state files. Terraform generates key names that include the values of the bucket and key variables.
```

### Задание с ** Провижионеры для app и db модуля

#### Добавление провижионеров для db VM

В конфигурации mongod.conf указана прослушка сервиса только на Ip 127.0.0.1. Для замены на 0.0.0.0 есть несколько вариантов. 1. можно запечь образ пакером с другой конфигурационным файлом mongod.conf и использовать новый образ в терраформе. 2. можно заменить конфигурационный файл mongod.conf через провижионер в терраформе.
Воспользуемся вторым способом, добавим в модуль db main.tf:

```
 connection {
    type  = "ssh"
    host  = yandex_compute_instance.db.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = var.path_mongod_conf
    destination = "/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop mongod",
      "sudo mv /tmp/mongod.conf /etc/mongod.conf",
      "sudo systemctl start mongod"
    ]
  }
```

Также необходимо передать внутренний Ip адрес db в переменную. Добавим в output.tf:

```
output "internal_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.ip_address
}
```

И переменную относительного пути расположения файла конфигурации сервиса mongod.
Т.к. мы переиспользуем модули, запуск может идти из stage и prod, следовательно относительный путь к файлу mongod.conf для модуля меняется.

```
variable path_mongod_conf {
  description = "mongod.conf file"
}
```

#### Добавление провижионеров для app VM

Сервис приложения puma при запуске проверяет переменную окружения DATABASE_URL, таким образом ему можно передать адрес базы данные расположенной на другой VM.
Настроим провижионер для этого.

```
 connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  provisioner "remote-exec" {
    inline = [
      "echo DATABASE_URL=${var.db_ip} > dburl.txt"
    ]
  }
  provisioner "file" {
    source      = var.path_puma_service
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = var.path_deploy_script
  }
```

В unit файл сервиса добавим загрузку переменных окружения, в секцию *[Service]*:

```
EnvironmentFile=/home/ubuntu/dburl.txt
```

 И переменные в variables.tf:
 ```
 variable path_puma_service {
  description = "path to file puma_service"
}
variable path_deploy_script {
  description = "path to file deploy.sh in modules/app"
}
variable db_ip {
  description = "app server ip address"
}
```

Результат проделанной работы, приложение, подключается к mongoDB по адресу *10.128.0.31:27017*:

```
buntu@fhmh5qthhapig97i0lvt:~$ sudo systemctl status puma
● puma.service - Puma HTTP Server
   Loaded: loaded (/etc/systemd/system/puma.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2021-08-05 15:08:52 UTC; 7min ago
 Main PID: 1729 (ruby2.3)
   CGroup: /system.slice/puma.service
           └─1729 puma 3.10.0 (tcp://0.0.0.0:9292) [reddit

Aug 05 15:08:52 fhmh5qthhapig97i0lvt bash[1729]: * Min threads: 0, max threads: 16
Aug 05 15:08:52 fhmh5qthhapig97i0lvt bash[1729]: * Environment: development
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: /home/ubuntu/reddit/helpers.rb:4: warning: redefining `object_id' may cause serious probl
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: D, [2021-08-05T15:08:53.122423 #1729] DEBUG -- : MONGODB | Topology type 'unknown' initia
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: D, [2021-08-05T15:08:53.122610 #1729] DEBUG -- : MONGODB | Server 10.128.0.31:27017 initi
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: D, [2021-08-05T15:08:53.137657 #1729] DEBUG -- : MONGODB | Topology type 'unknown' change
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: D, [2021-08-05T15:08:53.137826 #1729] DEBUG -- : MONGODB | Server description for 10.128.
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: D, [2021-08-05T15:08:53.137940 #1729] DEBUG -- : MONGODB | There was a change in the memb
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: * Listening on tcp://0.0.0.0:9292
Aug 05 15:08:53 fhmh5qthhapig97i0lvt bash[1729]: Use Ctrl-C to stop
```

## Домашнее задание №10 Управление конфигурацией. Знакомство с Ansible (ДЗ №8 Написание Ansible плейбуков на основе имеющихся bash скриптов)


### Написание плейбука деплоя приложения

Удалим ранее задеплоенное приложение с помощью модуля command

```bash
$ ansible app -m command -a 'rm -rf ~/reddit'
appserver | CHANGED | rc=0 >>
```

И произведем деплой приложения при помощи плейбука

```bash
$ ansible-playbook clone.yml

PLAY [Clone] ********************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************
ok: [appserver]

TASK [Clone repo] ***************************************************************************************************************************
changed: [appserver]

PLAY RECAP **********************************************************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

В результате выполнения мы видим, что произошло изменение, т.е. произошел деплой приложения (т.к. его не было по указанному пути). Ранее деплой не выполнялся из-за иденпотентности ansible.

### Задание со * - динамическое инвентори

### Настройка динамического инвентори

Для работы ansible с динамическим инвентори необходимо сформировать инвентори файл в формате json при этом он должен формироваться динамически, что бы ansible принял его в качестве инвентори.
Пример из документации:
```
After a few moments you should see some JSON output with information about your compute instances.
Once you confirm the dynamic inventory script is working as expected, you can tell Ansible to use the openstack_inventory.py script as an inventory file, as illustrated below:
ansible -i openstack_inventory.py all -m ansible.builtin.ping
```

Источником данных для динамического инвентори будем использовать вывод команды:
```bash
terraform state pull
```
Напишем скрипт обработки данного файл и сохраним inventory.json в динамическом формате. Сам файл inventory.json для работы ansible не нужен, он нужен только для просмотра содержания.
В тоже время сам скрипт *dynamic_inventory_json.py* будет входным файлом для JSON-инвентори.
Для того чтобы команда *ansible all -m ping* выполнилась корректно, в ansible.cfg укажем параметр.
```
inventory = ./dynamic_inventory_json.py
```
ansible понимая, что ему на вход подается JSON-инвентори сам добавляет ключ *--list* необходимый для работы *dynamic_inventory_json.py*

#### Отличия статического и динамического JSON

В статическом JSON хосты перечислены списком в формате "ключ : значение", даже если значение null, а в динамическом JSON хосты представлены списком в квадратных скобках, в виде только имен "ключ". При этом значения вынесены в отдельную секцию _meta/hostvars. Таким образом сначала идут логические группировки хостов по группам  без повторения значений если хост входит в разные групп одновременно.

Пример статического JSON:
```
{
  "app": {
    "hosts": {
      "appserver": {
        "ansible_host": "178.154.220.97"
      }
    }
  },
  "db": {
    "hosts": {
      "dbserver": {
        "ansible_host": "84.201.172.156"
      }
    }
  }
}
```

Пример динамического JSON
```
{
    "app": {
        "hosts": [
            "appserver"
        ]
    },
    "db": {
        "hosts": [
            "dbserver"
        ]
    },
    "_meta": {
        "hostvars": {
            "appserver": {
                "ansible_host": "178.154.220.97"

            },
            "dbserver": {
                "ansible_host": "84.201.172.156"
            }
        }
    }
}
```

## Домашнее задание №11 Продолжение знакомства с Ansible: templates, handlers, dynamic inventory, vault, tags (ДЗ №9 Управление настройками хостов и деплой приложения при помощи Ansible.)

### Основное задание

В результате работы над домашним заданием, мы подготовили:
1. плейбук *reddit_app_one_play.yml* с одним сценарием, сразу на все хосты, выбор тасков осуществляется по тегам и требуется указывать имя хоста. Необходимо помнить какой тег относится к какому хосту.
2. плейбук *reddit_app_multiple_plays.yml* с несколькими сценариями в одному плейбуке, таким образом, каждый сценарий связан с конкретным хостом и тегом, таким обращом достаточно указать нужный тег и сценарий сам сработает на нужном хосте.
3. плейбук *site.yml*, который является группировкой для трех отдельных плейбков. Данный подход позволяет уменьшить размер отдельных плейбуков и разделить их логически на несколько.

### Задание со * - использование динамического инвентори в плейбуков

Доработаем скрип динамического инвентори dynamic_inventory_json.py до версии 2 (dynamic_inventory_json2.py):
1. добавим загрузку значения переменной окружения TF_STATE из файла *env_tf_state.env*, если файл не найден, то используется TF_STATE из шела
2. В полученных данных из terraform state pull? выгрузим внутренний IP адрес mongoDB? в файл vars.json с переменной импортируемой в ansible

Таким образом при запуске прейбука *ansible-playbook site.yml* нам теперь не требуется менять IP адреса в переменных самого плейбука, т.к. у нас динамически формируемая инфраструктура.

### Провижининг в Packer

Создадим плейбуки ansible/packer_app.yml и ansible/packer_db.yml на основе аналогичных bash-скриптов изпользующихся в конфигурации с пакером.
Заменим секции provision в образах пакера packer/app.json и packer/db.json на Ansible.

Запустим сборку образов Packer'ом:
```bash
packer build -var-file=packer/variables.json  packer/app.json

yandex: output will be in this color.

==> yandex: Creating temporary ssh key for instance...
==> yandex: Using as source image: fd869u2laf181s38k2cr (name: "ubuntu-1604-lts-1612430962", family: "ubuntu-1604-lts")
==> yandex: Use provided subnet id e9bhddb5c34atpg4rd2j
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmhl7q55akrb7uhi98g to become active...
    yandex: Detected instance IP: 62.84.113.75
==> yandex: Using SSH communicator to connect: 62.84.113.75
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Setting up proxy adapter for Ansible....
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/tmp/ansible-key888675944 -i /tmp/packer-provisioner-ansible782643367 /home/darkon/DarkonGH_infra/ansible/packer_app.yml
    yandex:
    yandex: PLAY [Install Ruby and Bundler] ************************************************
    yandex:
    yandex: TASK [Gathering Facts] *********************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [Install packages for app] ************************************************
    yandex: changed: [default]
    yandex:
    yandex: PLAY RECAP *********************************************************************
    yandex: default                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    yandex:
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-app-base-1630613651
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 4 minutes 18 seconds.

==> Wait completed after 4 minutes 18 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1630613651 (id: fd8i00npgi61kun4ah1b) with family name reddit-app-base
```

```
packer build -var-file=packer/variables.json  packer/db.json

yandex: output will be in this color.

==> yandex: Creating temporary ssh key for instance...
==> yandex: Using as source image: fd869u2laf181s38k2cr (name: "ubuntu-1604-lts-1612430962", family: "ubuntu-1604-lts")
==> yandex: Use provided subnet id e9bhddb5c34atpg4rd2j
==> yandex: Creating disk...
==> yandex: Creating instance...
==> yandex: Waiting for instance with id fhmhl7q55akrb7uhi98g to become active...
    yandex: Detected instance IP: 62.84.113.75
==> yandex: Using SSH communicator to connect: 62.84.113.75
==> yandex: Waiting for SSH to become available...
==> yandex: Connected to SSH!
==> yandex: Provisioning with Ansible...
    yandex: Setting up proxy adapter for Ansible....
==> yandex: Executing Ansible: ansible-playbook -e packer_build_name="yandex" -e packer_builder_type=yandex --ssh-extra-args '-o IdentitiesOnly=yes' -e ansible_ssh_private_key_file=/tmp/ansible-key888675944 -i /tmp/packer-provisioner-ansible782643367 /home/darkon/DarkonGH_infra/ansible/packer_app.yml
    yandex:
    yandex: PLAY [Install Ruby and Bundler] ************************************************
    yandex:
    yandex: TASK [Gathering Facts] *********************************************************
    yandex: ok: [default]
    yandex:
    yandex: TASK [Install packages for app] ************************************************
    yandex: changed: [default]
    yandex:
    yandex: PLAY RECAP *********************************************************************
    yandex: default                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    yandex:
==> yandex: Stopping instance...
==> yandex: Deleting instance...
    yandex: Instance has been deleted!
==> yandex: Creating image: reddit-app-base-1630613651
==> yandex: Waiting for image to complete...
==> yandex: Success image create...
==> yandex: Destroying boot disk...
    yandex: Disk has been deleted!
Build 'yandex' finished after 4 minutes 18 seconds.

==> Wait completed after 4 minutes 18 seconds

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: reddit-app-base-1630613651 (id: fd8i00npgi61kun4ah1b) with family name reddit-app-base
```

Соберем стейдж окружение с помощью *terraform apply* на основе новых образов (необходимо изменить id образов в файле terraform.tfvars).
```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "62.84.115.153"
external_ip_address_db = "62.84.115.7"
internal_ip_address_db = "10.128.0.17"
```

Запустим ansible-playbook site.yml и убедимся в работе нашего приложения с dynamic inventory:

```bash
darkon@darkonVM:~/DarkonGH_infra/ansible (ansible-2)$ ansible-playbook site.yml

PLAY [Configure MongoDB] **********************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************
ok: [dbserver]

TASK [Change mongo config file] ***************************************************************************************************************************
changed: [dbserver]

RUNNING HANDLER [restart mongod] **************************************************************************************************************************
changed: [dbserver]

PLAY [Configure App] **************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************
ok: [appserver]

TASK [Add unit file for Puma] *****************************************************************************************************************************
changed: [appserver]

TASK [Load variable db_host for db_config.j2] *************************************************************************************************************
ok: [appserver]

TASK [debug] **********************************************************************************************************************************************
ok: [appserver] => {
    "db_host": "10.128.0.17"
}

TASK [Add config for DB connection] ***********************************************************************************************************************
changed: [appserver]

TASK [enable puma] ****************************************************************************************************************************************
changed: [appserver]

RUNNING HANDLER [reload puma] *****************************************************************************************************************************
changed: [appserver]

PLAY [Deploy App] *****************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************
ok: [appserver]

TASK [Fetch the latest version of application code] *******************************************************************************************************
changed: [appserver]

TASK [Bundle install] *************************************************************************************************************************************
changed: [appserver]

RUNNING HANDLER [restart puma] ****************************************************************************************************************************
changed: [appserver]

PLAY RECAP ************************************************************************************************************************************************
appserver                  : ok=11   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
dbserver                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0                   : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
