FROM ubuntu:22.04

# Install required packages + disable php prompt
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update
RUN apt-get install -y --fix-missing apache2 php libapache2-mod-php php-gd php-json php-mysql php-curl \
    php-mbstring php-intl php-imagick php-xml php-zip nano openssh-server sudo git npm nodejs

# Install Nextcloud PHP dependencies
RUN apt-get install -y php-bz2 php-ldap php-smbclient php-ftp php-imap php-gmp

# Create user hooman with password 1996 and add to sudoers
RUN useradd -m hooman && \
    echo "hooman:1996" | chpasswd && \
    adduser hooman sudo

# Allow SSH for user hooman
RUN mkdir /home/hooman/.ssh && \
    chown hooman:hooman /home/hooman/.ssh && \
    chmod 700 /home/hooman/.ssh

# Start services
RUN service ssh start
RUN service apache2 start

# Install newer NodeJS
RUN npm i -g n && \
n i 14 && \
hash -r

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

# Set working directory
WORKDIR /var/www/

# Expose ports for Apache and SSH
EXPOSE 80 22
# start apache and ssh
CMD service apache2 start && service ssh start && tail -f /dev/null
# Create nextcloud.conf file in apache2/sites-available/
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/nextcloud.conf
RUN echo 'DocumentRoot /var/www/nextcloud/' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo 'ServerName  your.server.com' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo  '<Directory /var/www/nextcloud/>' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo 'Require all granted' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo 'AllowOverride All' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo 'Options FollowSymLinks MultiViews' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo '<IfModule mod_dav.c>' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo 'Dav offn' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo '</IfModule>' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo '</Directory>' >> /etc/apache2/sites-available/nextcloud.conf
RUN echo '</VirtualHost>' >> /etc/apache2/sites-available/nextcloud.conf


# Enable nextcloud.conf and set as default page
RUN a2ensite nextcloud.conf && a2dissite 000-default.conf && \
service apache2 restart

#Download nextcloud
WORKDIR /var/www/
RUN wget https://download.nextcloud.com/server/releases/nextcloud-25.0.5.tar.bz2
RUN tar xvf nextcloud-25.0.5.tar.bz2
#grant privileges
RUN chown -R www-data /var/www/
#DONE
CMD service apache2 start && service ssh start && tail -f /dev/null
