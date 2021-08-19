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
Как выяснилось, при повтороной настройке, я ранее внес команду *GatewayPorts yes* не в тот конфиг файл,
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

#### еще один варинт подключения одной командой

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

Настройка алиаса  someinternalhost

Создадим файл *~/.ssh/config*
Добавим парметры удаленного хоста:

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

Уснатовка vpn будет производится на Ubuntu 18.04.5 LTS, для этого внесем изменения в скрипт **/vpn-bastion/setupvpn.sh**.
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
После настройки certbot проверяем, что у нас работает безопастное подключение в браузере <https://178-154-231-92.sslip.io/#>

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

* Создан сервисный аккаунт для Packer в Yandex Cloud и делигированы права.
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
провижинеров (connection).

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
* Добавим вывод IP Адреса балансирощика в output переменную:

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

external_ip_address_app = "178.154.207.150"
external_ip_address_app1 = "178.154.220.113"
lb_ip_address = tolist([
 "84.201.134.115",
])
```

* Проблемы конфигурации деплоя приложения на два инстанса - т.к. у нас в развертываемом приложении используется база данных MongoDB на каждом инстанесе, то получается должно быть настроено зеркалирование или репликация данных между БД, для корректной работы приложения с балансировщиком. А также присутсвует избыточная конфигурация в коде.

* Описание создания идентичных инстантов через парметр count, в *main.tf* добавим:

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

добавим в *main.tf* следующую конрфигурацию:

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

Неявная зависимость видна при созданиии инстанса, terraform apply, сначала создаются ресурсы сети и только потом создается VM:

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

#### Подготвока образов диска Packer'ом

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
Выполним компнуд для загрузки модулей:

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

Создадим конфигруацию stage и prod с учетом использования общих модулей, принцип DRY (Don't repeat youself).
Скопируем файлы: *key_tf.json  main.tf  outputs.tf terraform.tfvars  terraform.tfvars.example  variables.tf*  из папки terraform/ в
terraform/stage и нициализируем terraform в каждой папке:

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

Для настройки воспользуемcя [инструкцией](<https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-state-storage>)

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

В ходе тестов с Yandex Cloud выяснилось, что блоикровка применения конфигурации не работает. Т.к. нет поддержки DynamoDb.
Для примера в AWS S3 необходимо создать dyanamodb_table в существующей DaynamoDB, после этого включится блокировка удаленного стейт файла.

```
Stores the state as a given key in a given bucket on Amazon S3. This backend also supports state locking and consistency checking via Dynamo DB, which can be enabled by setting the dynamodb_table field to an existing DynamoDB table name. A single DynamoDB table can be used to lock multiple remote state files. Terraform generates key names that include the values of the bucket and key variables.
```

### Задание с ** Провижинеры для app и db модуля

#### Добавление провижионеров для db VM

В конфигрукции mongod.conf указана прослушка сервиса только на Ip 127.0.0.1. Для замены на 0.0.0.0 есть несколько вариантов. 1. можно запечь образ пакером с другой конфигурационным файлом mongod.conf и использовать новый образ в терраформе. 2. можно заменить конфигурационный файл mongod.conf через провижионер в терраформе.
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

## Домашнее задание №8 Управление конфигурацией. Знакомство с Ansible (ДЗ №8 Написание Ansible плейбуков на основе имеющихся bash скриптов)
