# -*- mode: ruby -*-
# vi: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
  :"logsBASHing" => {
             :box_name => "centos/7",
             :box_version => "2004.01",
             :cpus => 2,
             :memory => 4096,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.provider "virtualbox" do |vb|
        vb.memory = boxconfig[:memory]
        vb.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", inline: <<-SHELL
	      yum install -y wget mailx #flock
        mkdir /logparser/
        mkdir /weblogs/
        wget -P /logparser/ https://raw.githubusercontent.com/olegizt/DZ10_BASH/main/logparser.sh
        wget -P /weblogs/ https://raw.githubusercontent.com/olegizt/DZ10_BASH/main/access-web.log
        chmod +x /logparser/logparser.sh
        sudo crontab -l | { cat; echo "0 * * * * /usr/bin/flock -xn /var/lock/logparser.lck -c 'sh /logparser/logparser.sh'"; } | crontab -
        echo '#!/bin/bash' >> /usr/local/sbin/motd.sh
        chmod +x /usr/local/sbin/motd.sh
        echo 'printf "\e[0;37;42mПривет! Проверка настроек ДЗ №10 - BASH.\nДля проверки работы стенда проверьте содержимое файла /var/spool/mail/root.\nСодержимое этого файла будет дополняться каждый час информацией а парсинге лога вебсервера.\nСкрипт парсинга можно запустить вручную командой sudo /logparser/logparser.sh\e[0m\n"' >> /usr/local/sbin/motd.sh
        echo "PrintMotd no" >> /etc/ssh/sshd_config
        systemctl restart sshd
        echo '/usr/local/sbin/motd.sh' >> /etc/profile
      SHELL
    end
  end
end

