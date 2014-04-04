FROM centos

# telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk which telnet unzip openssh-server sudo openssh-clients
# enable no pass and speed up authentication
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/;s/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# enabling sudo group
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
# enabling sudo over ssh
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre

ENV FABRIC8_KARAF_NAME root
ENV FABRIC8_BINDADDRESS 0.0.0.0

# add a user for the application, with sudo permissions
RUN useradd -m fabric8 ; echo fabric8: | chpasswd ; usermod -a -G wheel fabric8

# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile


WORKDIR /home

RUN curl --silent --output fabric8.zip https://repository.jboss.org/nexus/content/repositories/fs-snapshots/io/fabric8/runtime/fabric8-tomcat/1.1.0-SNAPSHOT/fabric8-tomcat-1.1.0-20140402.142713-2.tar.gz
#RUN curl --silent --output fabric8.zip https://repository.jboss.org/nexus/content/groups/ea/io/fabric8/runtime/fabric8-tomcat/1.0.0.redhat-366/fabric8-tomcat-1.0.0.redhat-366.zip
RUN unzip -q fabric8.zip 
RUN ls -al
RUN mv fabric8-tomcat-1.1.0-SNAPSHOT fabric8
#RUN mv fabric8-tomcat-1.0.0.redhat-366 fabric8
RUN rm fabric8.zip
RUN chown -R fabric8:fabric8 fabric8

WORKDIR /home/fabric8/etc

# lets remove the karaf.name by default so we can default it from env vars
RUN sed -i '/karaf.name=root/d' system.properties 

RUN echo bind.address=0.0.0.0 >> system.properties
RUN echo fabric.environment=docker >> system.properties

# lets remove the karaf.delay.console=true to disable the progress bar
RUN sed -i '/karaf.delay.console=true/d' config.properties 
RUN echo karaf.delay.console=false >> config.properties

# lets add a user - should ideally come from env vars?
RUN echo >> users.properties 
RUN echo admin=admin,admin >> users.properties 

# lets enable logging to standard out
RUN echo log4j.rootLogger=INFO, stdout, osgi:* >> org.ops4j.pax.logging.cfg 

WORKDIR /home/fabric8

# ensure we have a log file to tail 
#RUN mkdir -p data/log
#RUN echo >> data/log/karaf.log

RUN curl --silent --output startup.sh https://raw.github.com/fabric8io/fabric8-tomcat-docker/master/startup.sh
RUN chmod +x startup.sh

EXPOSE 22 1099 2181 8101 8080 9300 9301 44444 61616 

CMD /home/fabric8/startup.sh