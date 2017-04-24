#!/usr/bin/bash
# This script intended for preparing Oracle Linux/RHEL/CentOS machine to run VSTS private agent and 
# deploy and build Java EE Apps to Oracle WebLogic Server

# Parameters
vsts_account_name=
vsts_personal_access_token=
vsts_agent_name=vsts-agent-wls
vsts_agent_pool_name=vsts-wls
user_account=

# Set up variables
vsts_url=https://$vsts_account_name.visualstudio.com
agent_url=https://github.com/Microsoft/vsts-agent/releases/download/v2.115.0/vsts-agent-rhel.7.2-x64-2.115.0.tar.gz
agent_tar=${agent_url##*/}
agent_home=/opt/vstsagent

jdk_url=http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm 
jdk_rpm=${jdk_url##*/}

maven_url=http://www-eu.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz
maven_tar=${maven_url##*/}
maven_dir=$(basename $maven_tar .tar.gz)
maven_home=/usr/local/${maven_dir}

git_url=https://www.kernel.org/pub/software/scm/git/git-2.9.2.tar.gz
git_tar=${git_url##*/}
maven_dir=$(basename $git_tar .tar.gz)
git_home=/usr/src/${maven_dir}

# Installing all required libs
echo "Installing required libs..."
sudo yum -y install libunwind.x86_64 icu
sudo yum -y install wget deltarpm epel-release unzip libunwind gettext libcurl-devel openssl-devel zlib libicu-devel 
sudo yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
sudo yum -y install gcc perl-ExtUtils-MakeMaker
# Removing the current version of GIT 
sudo yum -y remove git

# Downloading all required software components
echo "Downloading all required software components..."
cd /tmp
# Downloading JDK 8
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${jdk_url}
# Downloading Maven
wget ${maven_url}
# Downloading VSTS Agent
wget ${agent_url}
# Downloading GIT
wget ${git_url}

# Unpacking software components
echo "Unpacking software components..."
# Maven
echo "Maven..."
sudo mkdir ${maven_home}
sudo tar -xzf ${maven_tar} --strip-components=1 -C ${maven_home}
# GIT
echo "GIT..."
sudo mkdir ${git_home}
sudo tar -xzf ${git_tar} --strip-components=1 -C ${git_home}
# VSTS Agent
echo "VSTS Agent..."
sudo mkdir ${agent_home}
cd ${agent_home}
sudo tar -xzf /tmp/${agent_tar}

# Installing JDK 8
echo "Installing JDK 8..."
sudo rpm -ivh /tmp/${jdk_rpm}

# Installing Git
echo "Installing Git..."
cd ${git_home}
sudo make prefix=/usr/local/git all
sudo make prefix=/usr/local/git install

cd /tmp
# Creating shell script to set env. variables in /etc/profile.d/
echo "Configuring environment..."
javapath=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")
cat <<EOF > /tmp/setBuildENV.sh
export JAVA_HOME=$javapath
export PATH=\$PATH:$javapath/bin:$maven_home/bin:/usr/local/git/bin
EOF

chmod a+x /tmp/setBuildENV.sh
sudo mv /tmp/setBuildENV.sh /etc/profile.d/ 
. /etc/profile.d/setBuildENV.sh

export JAVA_HOME=$javapath
export PATH=$PATH:$javapath/bin:$maven_home/bin:/usr/local/git/bin

# Configure agent
echo "Running agent configuration..."
cd ${agent_home}
sudo -u ${user_account} bash ${agent_home}/config.sh configure --url $vsts_url --agent $vsts_agent_name --pool $vsts_agent_pool_name --nostart --acceptteeeula --auth PAT --token $vsts_personal_access_token --unattended

# Configure agent to run as a service
echo "Configuring agent to run as a service..."
sudo bash ${agent_home}/svc.sh install
sudo bash ${agent_home}/svc.sh start

# Updating env.variables in Agen configuration
sudo bash ${agent_home}/svc.sh stop
./env.sh
sudo bash ${agent_home}/svc.sh start

echo "Done!"