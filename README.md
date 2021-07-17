# DarkonGH_infra
DarkonGH Infra repository

# Блок проверки ДЗ

bastion_IP = 178.154.231.92
someinternalhost_IP = 10.128.0.12

testapp_IP = 178.154.240.105
testapp_port = 9292

# Домашнее задание №3 *Знакомство с облачной инфраструктурой. Yandex.Cloud*

## Самостоятельное задание 1 ssh

### Добавление приватного ключа в ssh-agent локальной машины
Выполняется командой *ssh-add C:\Users\darkon\.ssh\appuser*
предварительно необходимо запустить службу *OpenSSH Authentication Agent*

### Подключение на машину *bastion*

>PS C:\WINDOWS\system32> ssh -A appuser@217.28.231.251
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

> * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@bastion:~$

### Настройка OpenSSH сервера
Внесем параметры, необходимые для перенаправления подключения, в конфигурационный файл **/etc/ssh/sshd_config**:
*AllowTcpForwarding yes*
*GatewayPorts yes*
Перезапустим OpenSSH сервис командой *sudo systemctl restart sshd*.

### Настройка перенаправления подключения на VM *bastion*
На машине *bastion* настроим перенаправление подключения с локального порта 22022 на машину someinternalhost с IP 10.128.0.12, порт 22, командой:
*appuser@bastion:~$ ssh -fN -L 22022:localhost:22 10.128.0.12*

Для проверки подключения введем команду *ssh appuser@localhost -p 22022*

>appuser@bastion:~$ ssh appuser@localhost -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 >* Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$

Судя по приглашению *appuser@someinternalhost* подключение прошло успешно.

### Подключимся с локального рабочего устройства в одну команду:

*ssh -A appuser@178.154.231.92 -p 22022*
где IP адрес 178.154.231.92 машины *bastion*

>PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 -p 22022
ssh: connect to host 178.154.231.92 port 22022: Connection refused

Подключение должно было пройти напрямую на машину *someinternalhost*, но возникла ошибка.
По каким то причинам порт 22022 блокируется.
Просмотр iptables на машине *bastion* показывает, что все порты открыты (применена политика ACCEPT):
appuser@bastion:~$ sudo iptables -L -nv
>Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

>Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

>Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Изучение документации Yandex Cloud не дает ответа какие порты блокируются и блокируются ли вообще:
https://cloud.yandex.ru/docs/vpc/concepts/network
>Для виртуальных машин Yandex Compute Cloud и хостов баз данных доступ из интернета и в интернет открыт через публичные IP-адреса.

Вывод: Недостаточно информации для завершения задания
Вывод2: Судя по локальному IP адресу *Bastion* VM находится за NAT, хотя и имеет публичный IP адрес в Yandex Cloud (YC).
В таком случае требуется настроить Port Forwarding, настроек которого в YC не обнаружил.

### Проверка добавления внешнего IP адреса в команду перенаправления
По совету преподавателя, добавим явное указание локального IP адреса с которого получать подключение, ключ *-D внешний IP:порт*.
Но что-то тут не то, т.к. при запуске пишется перенаправление:
debug1: Local connections to 10.128.0.13:22022 forwarded to remote address socks:0
Данный ключ не подходит.

Пересоздадим *bastion* VM, т.к. был утрачен доступ из-за ошибки внесенной в sshd_config.
Как выяснилось, при повтороной настройке, я ранее внес команду *GatewayPorts yes* не в тот конфиг файл,
надо вносить в **ssh_config**. После этого команда: *ssh -fNv -L 22022:localhost:22 10.128.0.12* запустилась на всех интерфейсах

>debug1: Authentication succeeded (publickey).
Authenticated to 10.128.0.12 ([10.128.0.12]:22).
debug1: Local connections to *:22022 forwarded to remote address localhost:22
debug1: Local forwarding listening on 0.0.0.0 port 22022.
debug1: channel 0: new [port listener]
debug1: Local forwarding listening on :: port 22022.

Далее, подключаемся с локальной  рабочей машины, командой *ssh -A appuser@178.154.231.92 -p 22022* напрямую к someinternalhost, минуя bastion VM:
>PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 >* Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$ hostname
someinternalhost
appuser@someinternalhost:~$ uname -a
Linux someinternalhost 4.4.0-142-generic #168-Ubuntu SMP Wed Jan 16 21:00:45 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
appuser@someinternalhost:~$

Бонусом:
Выполняем еще одно перенаправление с локальной рабочей машины:
*PS C:\WINDOWS\system32> ssh  -fNv -A appuser@178.154.231.92 -L 22022:localhost:22022 178.154.231.92*
После этого можно подключаться локально на localhost:22022, попадая сразу на someinternalhost:

>PS C:\WINDOWS\system32> ssh -A appuser@localhost -p 22022
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

> * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$ hostname
someinternalhost
appuser@someinternalhost:~$

### еще один варинт подключения одной командой

Введем команду *ssh -A appuser@178.154.231.92 ssh 10.128.0.12*.

>PS C:\WINDOWS\system32> ssh -A appuser@178.154.231.92 ssh 10.128.0.12
Pseudo-terminal will not be allocated because stdin is not a terminal.
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 >* Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
hostname
someinternalhost
uname -a
Linux someinternalhost 4.4.0-142-generic #168-Ubuntu SMP Wed Jan 16 21:00:45 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux

## Дополнительное задание 1 ssh
Настройка алиаса  someinternalhost

Создадим файл *~/.ssh/config*
Добавим парметры удаленного хоста:

>Host someinternalhost
	HostName 127.0.0.1
	User appuser
	Port 22022

Теперь можно подключаться к удаленному серверу по алиасу:
*ssh someinternalhost*

>PS C:\WINDOWS\system32> ssh someinternalhost
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

> * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$

Подключение прошло успешно.

## Установка VPN-сервера для серверов Yandex.Cloud

Уснатовка vpn будет производится на Ubuntu 18.04.5 LTS, для этого внесем изменения в скрипт **/vpn-bastion/setupvpn.sh**.
Для внесения изменений в первоначальный скрипт использовалась статья https://www.howtoforge.com/how-to-setup-a-vpn-server-using-pritunl-on-ubuntu-1804/

После настройки vpn и подключения, проверяем подключение к someinternalhost с 10.128.0.12

>PS C:\WINDOWS\system32> ssh -A appuser@10.128.0.12
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 >* Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
appuser@someinternalhost:~$

## Подключение к bastion и someinternalhost

    bastion_IP = 178.154.231.92
    someinternalhost_IP = 10.128.0.12

## Дополнительное задание 2 VPN с сертификатом

Для создания подписанного сертификата при помощи сервиса Let's Encrypt используем доменное имя на основе IP адреса, сервиса sslip.io:
*178-154-231-92.sslip.io*
Далее производим настройку certbot согласно инструкции https://certbot.eff.org/lets-encrypt/ubuntubionic-other
После настройки certbot проверяем, что у нас работает безопастное подключение в браузере https://178-154-231-92.sslip.io/#

В настройках pritunl vpn сервера указываем Lets Encrypt Domain: *178-154-231-92.sslip.io*


# Домашнее задание №4 Деплой тестового приложения.

## параметры для автоматической проверки домашнего задания

    testapp_IP = 178.154.240.105
    testapp_port = 9292

## Создание новой ветки cloud-testapp

выполним команду *git checkout -b cloud-testapp*

##  Изучение написания Bash скриптов

Полезная статья для понимания bash скриптов https://habr.com/en/company/ruvds/blog/325522/

## Добавление скрипта деплоя приложения после создания инстанса

Дополнительный ключ *--metadata-from-file user-data=metadata.yaml*, который позволяет выполнять необходимые действия после создания инстанса.

> yc compute instance create \
 --name reddit-app \
 --hostname reddit-app \
 --memory=4 \
 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
 --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
 --metadata-from-file user-data=metadata.yaml \
 --metadata serial-port-enable=1


# Домашнее задание №5  Сборка образов VM при помощи Packer

## Основное ДЗ Сборка образов VM при помощи Packer

## Задание со * Построение Bake образа

В процессе сделано:

  *  Создан сервисный аккаунт для Packer в Yandex Cloud и делигированы права.
  *  Создание шаблона для Packer и его настройка (секции билдера и провиженеров)
  *  Собран образ с предустановленными ruby и mongodb
  *  Проверка загрузки ВМ из созданного образа. Проверка установки приложения
  *  Параметризация шаблона, перенос чувствительных данных в переменные variables.json

## Запуск сборки immunable образа

    packer build -var-file=./variables.json ./immutable.json
