#!/bin/sh
# This script intended to prepare Oracle Linux Azure VM to run VSTS Linux Build Agent  
# to support Java EE Apps deployment to Oracle WebLogic Server

# Validate input parameters
if [[ !("$#" -eq 5) ]]; 
    then echo "Parameters missing for vsts agent configuration." >&2
    exit 1
fi

# Parameters
vsts_account_name=$1
vsts_personal_access_token=$2
vsts_agent_name=$3
vsts_agent_pool_name=$4
user_account=$5

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

# Installing all required packages
echo "Installing required packages..."
yum -y install libunwind.x86_64 icu
yum -y install wget deltarpm epel-release unzip libunwind gettext libcurl-devel openssl-devel zlib libicu-devel 
yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
yum -y install gcc perl-ExtUtils-MakeMaker

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
mkdir ${maven_home}
tar -xzf ${maven_tar} --strip-components=1 -C ${maven_home}
# GIT
echo "GIT..."
mkdir ${git_home}
tar -xzf ${git_tar} --strip-components=1 -C ${git_home}
# VSTS Agent
echo "VSTS Agent..."
mkdir ${agent_home}
cd ${agent_home}
tar -xzf /tmp/${agent_tar}

# Installing JDK 8
echo "Installing JDK 8..."
rpm -ivh /tmp/${jdk_rpm}

# Installing Git
echo "Installing Git..."
cd ${git_home}
make prefix=/usr/local/git all
make prefix=/usr/local/git install
mv /usr/bin/git /usr/bin/git_Orig
ln -s /usr/local/git/bin/git /usr/bin/git

# =============================================================================
# Creating shell script to set env. variables in /etc/profile.d/
#echo "Configuring environment..."

javapath=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")

echo "LANG=en_US.UTF-8" > ${agent_home}/.env
echo "export LANG=en_US.UTF-8" >> /home/$user_account/.bashrc

export LANG=en_US.UTF-8
export JAVA_HOME=$javapath

echo "JAVA_HOME=${javapath}" >> ${agent_home}/.env
echo "export JAVA_HOME=${javapath}" >> /home/$user_account/.bashrc
echo "export PATH=\$PATH:${javapath}/bin:${maven_home}/bin:/usr/local/git/bin" >> /home/$user_account/.bashrc
echo $PATH:$javapath/bin:$maven_home/bin:/usr/local/git/bin > ${agent_home}/.path

export PATH=$PATH:$javapath/bin:$maven_home/bin:/usr/local/git/bin 

sed -i 's,Defaults    requiretty,#Defaults    requiretty,g' /etc/sudoers

# Configuring VSTS Agent
echo "Running agent configuration..."
cd ${agent_home}
sudo -u ${user_account} -E ./config.sh configure --unattended --url $vsts_url --agent $vsts_agent_name --pool $vsts_agent_pool_name --acceptteeeula --auth PAT --token $vsts_personal_access_token

# Installing VSTS Agent as a service
echo "Configuring agent to run as a service..."
sudo -E ./svc.sh install
sudo -E ./svc.sh start

echo "DONE!"