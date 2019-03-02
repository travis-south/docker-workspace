FROM phusion/baseimage:0.10.1

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

# Start as root
USER root

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

RUN echo ${PGID} && echo ${PUID}

RUN groupadd -g ${PGID} -o daker && \
    useradd -o -u ${PUID} -g daker -m daker -G docker_env && \
    usermod -p "*" daker

USER root

# Add the "PHP 7" ppa
RUN install_clean -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php

#
#--------------------------------------------------------------------------
# Software's Installation
#--------------------------------------------------------------------------
#

# Install "PHP Extentions", "libraries", "Software's"
RUN install_clean -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        php7.2-cli \
        php7.2-common \
        php7.2-curl \
        php7.2-intl \
        php7.2-json \
        php7.2-xml \
        php7.2-mbstring \
        php7.2-mysql \
        php7.2-pgsql \
        php7.2-sqlite \
        php7.2-sqlite3 \
        php7.2-zip \
        php7.2-bcmath \
        php7.2-memcached \
        php7.2-gd \
        php7.2-dev \
        pkg-config \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        libsqlite3-dev \
        sqlite3 \
        git \
        curl \
        vim \
        nano \
        postgresql-client \
        htop \
        libmcrypt-dev \
        openssh-client \
        libxml2-dev \
        libpng-dev \
        g++ \
        make \
        autoconf

#####################################
# Composer:
#####################################

# Install composer and add its bin to the PATH.
RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin" > ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# Source the bash
RUN . ~/.bashrc
ENV PATH ${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin

USER daker

RUN mkdir -p /home/daker/.docker-workspace/.composer/cache
RUN echo "export PATH=${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin" > ~/.bashrc
RUN echo "export COMPOSER_CACHE_DIR=/home/daker/.docker-workspace/.composer/cache" >> ~/.bashrc
RUN . ~/.bashrc
ENV PATH ${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin
ENV COMPOSER_CACHE_DIR /home/daker/.docker-workspace/.composer/cache
RUN mkdir -p ~/.composer
RUN composer global require hirak/prestissimo && composer --version

# Install PHPQATools
RUN composer global require symfony/config:^3 \
    symfony/console:^3 \
    symfony/event-dispatcher:^3 \
    symfony/finder:^3 \
    symfony/process:^3 \
    symfony/var-dumper:^3 \
    symfony/yaml:^3 \
    symfony/filesystem:^3 \
    travis-south/phpqatools:^3.0 \
    behat/mink-extension \
    behat/mink-goutte-driver \
    behat/mink-selenium2-driver \
    behat/mink-zombie-driver \
    drupal/coder:^8.2.0 \
    endouble/symfony3-custom-coding-standard \
    rregeer/phpunit-coverage-check
RUN phpcs --config-set installed_paths \
    $HOME/.composer/vendor/endouble/symfony3-custom-coding-standard,$HOME/.composer/vendor/drupal/coder/coder_sniffer

# Install Drush
USER daker
RUN composer global require drush/drush:^9.0 && drush --version

# Install Laravel artisan
USER daker
RUN composer global require laravel/installer && laravel --version

# Install NodeJS
USER root
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    install_clean nodejs && \
    nodejs --version
USER daker
RUN echo "export NPM_CONFIG_USERCONFIG=/home/daker/.docker-workspace/.npmrc" >> ~/.bashrc
ENV NPM_CONFIG_USERCONFIG /home/daker/.docker-workspace/.npmrc
RUN echo "cache=/home/daker/.docker-workspace/npm-cache" >> ~/.docker-workspace/.npmrc
RUN nodejs --version && \
    npm --version

# Install Yarn
USER root
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    install_clean yarn && \
    yarn --version
USER daker
RUN yarn --version && \
    echo "export YARN_CACHE_FOLDER=/home/daker/.docker-workspace/.yarn/cache" >> ~/.bashrc && \
    echo "export PATH=${PATH}:/home/daker/.yarn/bin" >> ~/.bashrc && \
    . ~/.bashrc
ENV YARN_CACHE_FOLDER /home/daker/.docker-workspace/.yarn/cache
ENV PATH ${PATH}:/home/daker/.yarn/bin

# Install Python/PIP
USER root
RUN install_clean python-pip && \
    python --version && \
    pip --version

# Install Ansible
USER root
RUN pip install --upgrade setuptools && \
    pip install ansible && \
    ansible --version
USER daker
RUN ansible --version

# Install AWS CLI
USER root
RUN install_clean groff
USER daker
RUN pip install awscli --upgrade --user
ENV PATH ${PATH}:/home/daker/.local/bin
RUN echo "export PATH=${PATH}:/home/daker/.local/bin" >> ~/.bashrc
RUN echo "export AWS_CONFIG_FILE=/home/daker/.docker-workspace/.aws/config" >> ~/.bashrc
RUN echo "export AWS_SHARED_CREDENTIALS_FILE=/home/daker/.docker-workspace/.aws/credentials" >> ~/.bashrc
ENV AWS_CONFIG_FILE /home/daker/.docker-workspace/.aws/config
ENV AWS_SHARED_CREDENTIALS_FILE /home/daker/.docker-workspace/.aws/credentials
RUN . ~/.bashrc && \
    aws --version

# Install Wodby CLI
USER root
RUN install_clean wget && \
    export WODBY_CLI_LATEST_URL=$(curl -s https://api.github.com/repos/wodby/wodby-cli/releases/latest | grep linux-amd64 | grep browser_download_url | cut -d '"' -f 4) && \
    wget -qO- "${WODBY_CLI_LATEST_URL}" | tar xz -C /usr/local/bin
USER daker
RUN wodby --help

# Install eslint and tslint
USER daker
RUN yarn global add babel-eslint eslint typescript tslint

# Install sonarscanner
USER root
RUN install_clean unzip \
    xz-utils \
    openjdk-8-jre-headless
RUN java -version
WORKDIR /
RUN curl -o sonar-scanner-cli.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.2.0.1227-linux.zip
RUN unzip sonar-scanner-cli.zip
RUN mv sonar-scanner-3.2.0.1227-linux sonar-scanner && \
    chmod 777 -R /sonar-scanner
RUN cd /usr/local/bin && ln -s /sonar-scanner/bin/sonar-scanner sonar-scanner
COPY sonar-scanner.properties /sonar-scanner/conf/sonar-scanner.properties
RUN rm -rf /sonar-scanner-cli.zip
WORKDIR /var/www/app
USER daker
RUN yarn global add tslint-sonarts
ENV NODE_PATH /usr/lib/node_modules
RUN echo "export NODE_PATH=/usr/lib/node_modules" >> ~/.bashrc
ENV SONAR_USER_HOME /home/daker/.docker-workspace/.sonar
RUN echo "export SONAR_USER_HOME=/home/daker/.docker-workspace/.sonar" >> ~/.bashrc
RUN . ~/.bashrc

# Install JMeter
USER root
ENV JMETER_HOME=/opt/jmeter \
    JMETER_VERSION=3.3 \
    PATH=/opt/jmeter/bin/:$PATH \
    PLUGINS_PATH=/tmp/plugins
RUN mkdir -p ${JMETER_HOME} \
    && wget -O /tmp/jmeter.tgz https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz \
    && tar -C /tmp -xvzf /tmp/jmeter.tgz \
    && mv /tmp/apache-jmeter-${JMETER_VERSION}/* ${JMETER_HOME} \
    && rm -rf /tmp/jmeter.tgz /tmp/apache-jmeter-${JMETER_VERSION} /var/cache/apk/* \
    && mkdir -p $PLUGINS_PATH \
    && wget https://jmeter-plugins.org/files/packages/jpgc-cmd-2.1.zip \
    && unzip -o -d $PLUGINS_PATH jpgc-cmd-2.1.zip \
    && cp $PLUGINS_PATH/lib/*.jar $JMETER_HOME/lib/ \
    && cp $PLUGINS_PATH/bin/* $JMETER_HOME/bin/ \
    && cp $PLUGINS_PATH/lib/ext/*.jar $JMETER_HOME/lib/ext/ \
    && rm -rf $PLUGINS_PATH
RUN /opt/jmeter/bin/jmeter.sh -n -v \
    && java -cp /opt/jmeter/lib/ext/jmeter-plugins-manager-0.20.jar org.jmeterplugins.repository.PluginManagerCMDInstaller
RUN /opt/jmeter/bin/PluginsManagerCMD.sh install jpgc-oauth,jpgc-json,jpgc-casutg,jpgc-graphs-additional,jpgc-synthesis && \
     chmod -R 777 /opt/jmeter
USER daker
ENV JMETER_HOME /opt/jmeter
RUN echo "export JMETER_HOME=/opt/jmeter" >> ~/.bashrc
ENV PATH ${PATH}:/opt/jmeter/bin
RUN echo "export PATH=${PATH}:/opt/jmeter/bin" >> ~/.bashrc
RUN . ~/.bashrc
RUN jmeter -n -v

# Install Apache bench
USER root
RUN install_clean apache2-utils && \
    ab -V

# Install siege
USER root
WORKDIR /
RUN install_clean openssl libssl-dev zlib1g zlib1g-dev
RUN curl -o siege.tar.gz -L http://download.joedog.org/siege/siege-4.0.4.tar.gz
RUN tar -zxf siege.tar.gz
RUN mv siege-4.0.4 siege
RUN chmod 777 -R siege
RUN cd siege && \
    ./configure && \
    make && \
    make install

# Install Kubectl
USER root
RUN install_clean apt-transport-https && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    touch /etc/apt/sources.list.d/kubernetes.list && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    install_clean kubectl
USER daker
RUN mkdir -p /home/daker/.docker-workspace/.kube && \
    touch /home/daker/.docker-workspace/.kube/config
ENV KUBECONFIG /home/daker/.docker-workspace/.kube/config
RUN echo "export KUBECONFIG=/home/daker/.docker-workspace/.kube/config" >> ~/.bashrc && \
    . ~/.bashrc


# Install Helm
USER root
WORKDIR /tmp
RUN curl -o helm-v2.9.1-linux-amd64.tar.gz -L https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz && \
    tar -zxf helm-v2.9.1-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    chmod a+x /usr/local/bin/helm
USER daker
RUN mkdir -p /home/daker/.docker-workspace/.helm
ENV HELM_HOME /home/daker/.docker-workspace/.helm
RUN echo "export HELM_HOME=/home/daker/.docker-workspace/.helm" >> ~/.bashrc && \
    . ~/.bashrc

# Clean up APT when done.
USER root
RUN apt-get update -y && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Polymer CLI
USER root
RUN npm install -g polymer-cli --unsafe-perm

# Install Angular CLI
USER root
RUN npm install -g @angular/cli
EXPOSE 8001

# Install Karma
USER root
RUN npm install -g karma-cli

# Install Lite-server
USER root
RUN npm install -g lite-server

# Install Golang
USER root
RUN wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
USER daker
ENV PATH ${PATH}:/usr/local/go/bin:/home/daker/golang/bin
RUN echo "export PATH=${PATH}:/usr/local/go/bin:/home/daker/golang/bin" >> ~/.bashrc
ENV GOPATH /home/daker/golang
RUN echo "export GOPATH=/home/daker/golang" >> ~/.bashrc
RUN . ~/.bashrc

# Install Minica
USER daker
RUN go get github.com/jsha/minica

# Install Certbot
USER root
RUN add-apt-repository ppa:certbot/certbot && \
    install_clean certbot

# Install Lite-server
USER root
RUN npm install -g source-map-explorer

# Install Dartlang
RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
    install_clean dart
USER daker
ENV PATH ${PATH}:/usr/lib/dart/bin
RUN echo "export PATH=${PATH}:/usr/lib/dart/bin" >> ~/.bashrc
ENV PATH ${PATH}:/home/daker/.pub-cache/bin
RUN echo "export PATH=${PATH}:/home/daker/.pub-cache/bin" >> ~/.bashrc
RUN . ~/.bashrc
RUN pub global activate stagehand && \
    pub global activate webdev

# Add daker to group tty
USER root
RUN usermod -a -G tty daker

# Install Gatsby-cli
USER root
RUN npm install -g gatsby-cli

# Install Grunt CLI
USER root
RUN npm install -g grunt-cli

# Install mysql client
USER root
RUN install_clean mysql-client

# Install Jest CLI
USER root
RUN npm install -g jest

# Install JQ
USER root
RUN install_clean jq

# Install docker client
USER root
RUN install_clean ca-certificates \
        software-properties-common \
        iputils-ping && \
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
        apt-key fingerprint 0EBFCD88 && \
        add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) \
                stable"
RUN install_clean docker-ce
RUN usermod -aG docker,root daker

# Install docker-compose
USER root
RUN curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
        chmod +x /usr/local/bin/docker-compose

# Install dig and whois
USER root
RUN install_clean whois dnsutils

# Install react-native-cli and create-react-native-app
USER root
RUN npm install -g react-native-cli create-react-native-app

# Install expo-cli
USER root
RUN npm install -g expo-cli

# Install ruby
USER root
RUN apt-add-repository -y ppa:rael-gc/rvm && \
       install_clean rvm
RUN /usr/share/rvm/bin/rvm install ruby 2.6.0
USER daker
RUN echo "source /usr/share/rvm/scripts/rvm" >> ~/.bashrc
RUN echo "export PATH=${PATH}:/usr/share/rvm/rubies/ruby-2.6.0/bin" >> ~/.bashrc
ENV PATH ${PATH}:/usr/share/rvm/rubies/ruby-2.6.0/bin

################################### Add your updates before this line ###################
USER root
COPY workspace-list /usr/local/bin/workspace-list
RUN chmod +x /usr/local/bin/workspace-list
CMD ["/usr/local/bin/workspace-list"]

# Update entrypoint
USER root
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Clean up APT when done.
USER root
RUN apt-get update -y && apt-get upgrade -y --allow-unauthenticated && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
