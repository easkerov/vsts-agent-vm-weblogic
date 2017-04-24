#!/usr/bin/bash
# This script intended for preparing Oracle Linux/RHEL/CentOS machine to run VSTS private agent and 
# deploy and build Java EE Apps to Oracle WebLogic Server

cd $HOME

# Downloading all required software components
echo "Downloading all required software components..."
# Downloading JDK 8
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm -O "jdk-8-linux-x64.rpm"
# Downloading Maven
wget http://www-eu.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz
# Downloading VSTS Agent
wget https://github.com/Microsoft/vsts-agent/releases/download/v2.115.0/vsts-agent-rhel.7.2-x64-2.115.0.tar.gz
# Downloading GIT
wget https://www.kernel.org/pub/software/scm/git/git-2.9.2.tar.gz


# Unpacking software components
echo "Unpacking software components..."
# VSTS Agent
mkdir vsts_agent && cd vsts_agent
tar zxvf vsts-agent-rhel.7.2-x64-2.115.0.tar.gz


# Maven
sudo tar xzvf apache-maven-3.5.0-bin.tar.gz -C /usr/local
# GIT
sudo tar zxfv git-2.9.2.tar.gz -C /usr/src


# Installing all required libs
echo "Installing required libs..."
sudo yum -y install libunwind.x86_64 icu
sudo yum -y install wget deltarpm epel-release unzip libunwind gettext libcurl-devel openssl-devel zlib libicu-devel 
sudo yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
sudo yum -y install gcc perl-ExtUtils-MakeMaker

# Installing JDK 8
sudo rpm -ivh jdk-8-linux-x64.rpm

# Installing Git
cd /usr/src/git-2.9.2
sudo make prefix=/usr/local/git all
sudo make prefix=/usr/local/git install

# Creating shell script to set env. variables in /etc/profile.d/
javapath=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")
cat <<EOF > $HOME/temp/setBuildENV.sh
export JAVA_HOME=$javapath
export PATH=$javapath/bin:usr/local/apache-maven-3.5.0/bin:/usr/local/git/bin:\$PATH
EOF

sudo chmod a+x $HOME/setBuildENV.sh
sudo cp $HOME/setBuildENV.sh /etc/profile.d/ 
source /etc/profile.d/setMVNJDKEnv.sh
