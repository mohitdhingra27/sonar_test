FROM centos:7

# Maven version to install
ENV MAVEN_INSTALL_VERSION 3.3.9

# Update system & install dependencies
RUN yum -y update \
	&& yum -y install java-1.8.0-openjdk-devel \
	&& yum -y clean all
	
RUN yum -y install wget	
	
# Install maven
RUN cd /tmp \
	&& wget ftp://mirror.reverse.net/pub/apache/maven/maven-3/${MAVEN_INSTALL_VERSION}/binaries/apache-maven-${MAVEN_INSTALL_VERSION}-bin.tar.gz \
	&& tar -xzf apache-maven-${MAVEN_INSTALL_VERSION}-bin.tar.gz -C /opt \
	&& ln -s /opt/apache-maven-${MAVEN_INSTALL_VERSION} /opt/apache-maven
	
# Create user and group for Bamboo
RUN groupadd -r -g 900 bamboo-agent \
	&& useradd -r -m -u 900 -g 900 bamboo-agent
	
COPY allprojectinfo.xml /root
CMD java -jar /root/atlassian-bamboo-agent-installer.jar
