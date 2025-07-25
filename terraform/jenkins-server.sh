#!/bin/bash
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian binary/ | tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# install java, nginx, and jenkins
echo "# $(date) Install Java 21, NGINX, and Jenkins..."
apt update
apt-get -y upgrade

apt-get -y install \
    openjdk-21-jdk \
    nginx \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3-pip \
    python3-venv

apt-get -y install jenkins

# configure jenkins
echo "# $(date) Configure Jenkins..."

## skip the installation wizard at startup
echo "# $(date) Skip the installation wizard on first boot..."
echo "JAVA_ARGS=\"-Djenkins.install.runSetupWizard=false\"" >> /etc/default/jenkins

## download the list of plugins
echo "# $(date) Download the list of plugins..."
wget https://raw.githubusercontent.com/jenkinsci/jenkins/master/core/src/main/resources/jenkins/install/platform-plugins.json

## get the suggested plugins
echo "# $(date) Use the keyword 'suggest' to find the suggested plugins in the list..."
grep suggest platform-plugins.json | cut -d\" -f 4 | grep -v name | tee suggested-plugins.txt

## download the plugin installation tool
plugin_manager_version=2.13.2
echo "# $(date) Download the plugin installation tool version ${plugin_manager_version}..."
wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${plugin_manager_version}/jenkins-plugin-manager-${plugin_manager_version}.jar

## run the plugin installation tool
echo "# $(date) Run the plugin installation tool..."
/usr/bin/java -jar ./jenkins-plugin-manager-${plugin_manager_version}.jar \
	--verbose \
    --skip-failed-plugins \
    --plugin-download-directory=/var/lib/jenkins/plugins \
    --plugin-file=./suggested-plugins.txt | tee /var/log/plugin-installation.log

## because the plugin installation tool runs as root, ownership on
## the plugin dir needs to be changed back to jenkins:jenkins
## otherwise, jenkins won't be able to install the plugins
echo "# $(date) Update the permissions on the plugins directory..."
chown -R jenkins:jenkins /var/lib/jenkins/plugins

# configure nginx
echo "# $(date) Configure NGINX..."
unlink /etc/nginx/sites-enabled/default

tee /etc/nginx/conf.d/jenkins.conf <<EOF
upstream jenkins {
    server 127.0.0.1:8080;
}

server {
    listen 80 default_server;
    listen [::]:80  default_server;
    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

echo "# $(date) Reload NGINX to pick up the new configuration..."
systemctl reload nginx

# install docker
echo "# $(date) Install docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt-get -y install docker-ce docker-ce-cli containerd.io
docker run hello-world

systemctl enable docker.service
systemctl enable containerd.service

usermod -aG docker ubuntu
usermod -aG docker jenkins

echo "# $(date) Restart Jenkins..."
systemctl restart jenkins

echo "# $(date) Copy the initial admin password to the root user's home directory..."
cp /var/lib/jenkins/secrets/initialAdminPassword ~

clear
echo "Installation is complete."

sudo echo "Username: admin" >> /root/jenkins_credentials.txt
sudo echo "Password: $(cat /var/lib/jenkins/secrets/initialAdminPassword)" >> /root/jenkins_credentials.txt
