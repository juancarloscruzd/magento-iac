#!/bin/bash
sudo apt update
sudo apt update
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
sudo a2enmod rewrite
sudo apt install mysql-client -y
sudo apt install -y php7.2 libapache2-mod-php7.2 php7.2-common php7.2-gmp php7.2-curl php7.2-soap php7.2-bcmath php7.2-intl php7.2-mbstring php7.2-xmlrpc php7.2-mysql php7.2-gd php7.2-xml php7.2-cli php7.2-zip
sudo sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/7.2/apache2/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/g' /etc/php/7.2/apache2/php.ini
sudo sed -i 's/max_execution_time = 30/max_execution_time = 360/g' /etc/php/7.2/apache2/php.ini
sudo systemctl restart apache2

sudo mkdir /home/magento
sudo useradd -d /home/magento -s /bin/bash magento
sudo chown -R magento:magento /home/magento
sudo sed -i 's/www-data/magento/g' /etc/apache2/envvars
sudo mkdir /home/magento/public_html
sudo mkdir /home/magento/public_html/magento
cd /home/magento/public_html/magento && sudo tar -xvf /home/ubuntu/magento.tar.gz
sudo chown -R magento:magento /home/magento
sudo chmod -R 755 /home/magento/public_html/magento

sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
sudo sed -i 's*DocumentRoot /var/www/html*DocumentRoot /home/magento/public_html/magento*g' /etc/apache2/sites-available/000-default.conf
sudo sed -i 's*<Directory /var/www/>*<Directory /home/magento/public_html/magento>*g' /etc/apache2/apache2.conf
sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
sudo systemctl restart apache2
sudo rm /home/ubuntu/magento.tar.gz
sudo rm /home/ubuntu/magento-2.sh