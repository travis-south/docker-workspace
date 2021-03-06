FROM phusion/baseimage:0.11

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
        php7.4-cli \
        php7.4-common \
        php7.4-curl \
        php7.4-intl \
        php7.4-json \
        php7.4-xml \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-pgsql \
        php7.4-sqlite \
        php7.4-sqlite3 \
        php7.4-zip \
        php7.4-bcmath \
        php7.4-memcached \
        php7.4-gd \
        php7.4-dev \
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
COPY --from=composer:1.9.2 /usr/bin/composer /usr/local/bin/composer
RUN echo "export PATH=${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin" > ~/.bashrc && \
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

# # Install PHPQATools
# RUN composer global require symfony/process:4.4.3 \
#     travis-south/phpqatools:5.0.0 \
#     behat/mink-extension:2.3.1 \
#     behat/mink-goutte-driver:1.2.1 \
#     behat/mink-selenium2-driver:1.3.1 \
#     behat/mink-zombie-driver:1.4.0 \
#     drupal/coder:8.3.4 \
#     rregeer/phpunit-coverage-check:0.1.6
# RUN phpcs --config-set installed_paths \
#     $HOME/.composer/vendor/drupal/coder/coder_sniffer

# Install Drush
#USER daker
#RUN composer global require drush/drush:9.7.0 && drush --version

# Install Laravel artisan
USER daker
RUN composer global require laravel/installer:3.0.1 && laravel --version

# Install NodeJS
USER root
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
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
RUN yarn global add babel-eslint@10.0.1 eslint@5.16.0 typescript@3.5.1 tslint@5.17.0

# Install sonarscanner
USER root
RUN install_clean unzip \
    xz-utils \
    openjdk-8-jre-headless
RUN java -version
WORKDIR /
RUN curl -o sonar-scanner-cli.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
RUN unzip sonar-scanner-cli.zip
RUN mv sonar-scanner-3.3.0.1492-linux sonar-scanner && \
    chmod 777 -R /sonar-scanner
RUN cd /usr/local/bin && ln -s /sonar-scanner/bin/sonar-scanner sonar-scanner
COPY sonar-scanner.properties /sonar-scanner/conf/sonar-scanner.properties
RUN rm -rf /sonar-scanner-cli.zip
WORKDIR /var/www/app
USER daker
RUN yarn global add tslint-sonarts@1.9.0
ENV NODE_PATH /usr/lib/node_modules
RUN echo "export NODE_PATH=/usr/lib/node_modules" >> ~/.bashrc
ENV SONAR_USER_HOME /home/daker/.docker-workspace/.sonar
RUN echo "export SONAR_USER_HOME=/home/daker/.docker-workspace/.sonar" >> ~/.bashrc
RUN . ~/.bashrc

# Install JMeter
USER root
ENV JMETER_HOME=/opt/jmeter \
    JMETER_VERSION=5.1.1 \
    PATH=/opt/jmeter/bin/:$PATH \
    PLUGINS_PATH=/tmp/plugins
RUN mkdir -p ${JMETER_HOME} \
    && wget -O /tmp/jmeter.tgz https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz \
    && tar -C /tmp -xvzf /tmp/jmeter.tgz \
    && mv /tmp/apache-jmeter-${JMETER_VERSION}/* ${JMETER_HOME} \
    && rm -rf /tmp/jmeter.tgz /tmp/apache-jmeter-${JMETER_VERSION} /var/cache/apk/* \
    && mkdir -p $PLUGINS_PATH \
    && wget https://jmeter-plugins.org/files/packages/jpgc-cmd-2.2.zip \
    && unzip -o -d $PLUGINS_PATH jpgc-cmd-2.2.zip \
    && cp $PLUGINS_PATH/lib/*.jar $JMETER_HOME/lib/ \
    && cp $PLUGINS_PATH/bin/* $JMETER_HOME/bin/ \
    && cp $PLUGINS_PATH/lib/ext/*.jar $JMETER_HOME/lib/ext/ \
    && rm -rf $PLUGINS_PATH
RUN /opt/jmeter/bin/jmeter.sh -n -v \
    && java -cp /opt/jmeter/lib/ext/jmeter-plugins-manager-1.3.jar org.jmeterplugins.repository.PluginManagerCMDInstaller
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
RUN apt-get clean && \
    install_clean apache2-utils && \
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
RUN curl -o helm-v2.14.1-linux-amd64.tar.gz -L https://storage.googleapis.com/kubernetes-helm/helm-v2.14.1-linux-amd64.tar.gz && \
    tar -zxf helm-v2.14.1-linux-amd64.tar.gz && \
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
RUN npm install -g polymer-cli@1.9.10 --unsafe-perm

# Install Angular CLI
USER root
RUN npm install -g @angular/cli@8.0.1

# Install Karma
USER root
RUN npm install -g karma-cli@2.0.0

# Install Lite-server
USER root
RUN npm install -g lite-server@2.5.3

# Install Golang
USER root
RUN wget https://dl.google.com/go/go1.12.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.12.5.linux-amd64.tar.gz
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
RUN npm install -g source-map-explorer@2.0.0

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
RUN npm install -g gatsby-cli@2.6.5

# Install Grunt CLI
USER root
RUN npm install -g grunt-cli@1.3.2

# Install mysql client
USER root
RUN install_clean mysql-client

# Install Jest CLI
USER root
RUN npm install -g jest@24.8.0

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
RUN curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
        chmod +x /usr/local/bin/docker-compose

# Install dig and whois
USER root
RUN install_clean whois dnsutils

# Install react-native-cli, create-react-app and create-react-native-app
USER root
RUN npm install -g react-native-cli@2.0.1 create-react-native-app@2.0.2 create-react-app@3.0.1

# Install expo-cli
USER root
RUN npm install -g expo-cli@2.19.1 --allow-root --unsafe-perm

# Install ruby
USER root
RUN apt-add-repository -y ppa:rael-gc/rvm && \
       install_clean rvm
RUN /usr/share/rvm/bin/rvm install ruby 2.6.0
USER daker
RUN echo "source /usr/share/rvm/scripts/rvm" >> ~/.bashrc
RUN echo "export PATH=${PATH}:/usr/share/rvm/rubies/ruby-2.6.0/bin" >> ~/.bashrc
ENV PATH ${PATH}:/usr/share/rvm/rubies/ruby-2.6.0/bin

# Add AWS IAM auth
USER root
RUN curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && \
        chmod +x /usr/local/bin/aws-iam-authenticator && \
        aws-iam-authenticator help

# Install eksctl
USER root
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
        mv /tmp/eksctl /usr/local/bin && \
        chmod +x /usr/local/bin/eksctl && \
        eksctl

# Install Serverless CLI, NestJS CLI, OpenFaaS CLI, Hugo, deno
USER root
RUN npm install -g serverless && sls --version && \
    npm install -g @nestjs/cli && nest --help && \
    curl -sL https://cli.openfaas.com | sh && \
    curl -LSs https://github.com/gohugoio/hugo/releases/download/v0.55.6/hugo_extended_0.55.6_Linux-64bit.deb \
        -o /tmp/hugo_extended_0.55.6_Linux-64bit.deb && \
        dpkg -i /tmp/hugo_extended_0.55.6_Linux-64bit.deb && \
        hugo version
USER daker
RUN faas-cli --help && \
    curl -fsSL https://deno.land/x/install/install.sh | sh && \
    echo "export PATH=${PATH}:/home/daker/.deno/bin" >> ~/.bashrc
ENV PATH PATH=${PATH}:/home/daker/.deno/bin

# Install blackfire, PHP XDebug, envsubst, traceroute, terraform, Set timezone to Asia/Manila
USER root
ENV TZ 'Asia/Manila'
RUN apt-get update -y && apt-get upgrade -y --allow-unauthenticated && \
    curl -LSs https://packages.blackfire.io/binaries/blackfire-agent/1.27.4/blackfire-cli-linux_amd64 \
    -o /usr/local/bin/blackfire && \
    chmod +x /usr/local/bin/blackfire && \
    install_clean php7.4-xdebug gettext-base traceroute tcptraceroute && \
    curl -LSs https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_linux_amd64.zip \
    -o /tmp/terraform_0.12.8_linux_amd64.zip && \
    unzip /tmp/terraform_0.12.8_linux_amd64.zip && ls -alh && \
    pwd && ls -alh && mv terraform /usr/bin/ && \
    chmod +x /usr/bin/terraform && \
    install_clean tzdata cmake && \
    echo "Asia/Manila" | tee /etc/timezone && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/Asia/Manila /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Install Symfony installer
USER daker
RUN curl -sS https://get.symfony.com/cli/installer | bash && \
    chmod -R 777 /home/daker/.symfony/bin/* && \
    echo "export PATH=${PATH}:/home/daker/.symfony/bin" >> ~/.bashrc
ENV PATH ${PATH}:/home/daker/.symfony/bin

# Install chromium for headless testing, sshuttle, sudo, gollum, zsh, ohmyzsh, keybase, boundary
USER root
RUN install_clean gconf-service \
    libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 \
    libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
    libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
    libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
    libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 \
    libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates \
    fonts-liberation libappindicator1 libnss3 lsb-release \
    xdg-utils wget sshuttle sudo && \
    echo "daker	ALL=(ALL)	NOPASSWD:ALL" > /etc/sudoers.d/daker && \
    gem install gollum github-markdown && \
    install_clean zsh powerline fonts-powerline fuse lsof && \
    curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb && \
    apt install ./keybase_amd64.deb && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    install_clean boundary
USER daker
RUN run_keybase



################################### Add your updates before this line ###################
# Add custom script
USER daker
ADD custom-scripts /custom-scripts
RUN echo "export PATH=${PATH}:/custom-scripts" >> ~/.bashrc
ENV PATH ${PATH}:/custom-scripts

USER root
COPY workspace-list /usr/local/bin/workspace-list
RUN chmod +x /usr/local/bin/workspace-list
CMD ["/usr/local/bin/workspace-list"]

# Update entrypoint and clean up APT when done.
USER root
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
RUN apt-get update -y && apt-get upgrade -y --allow-unauthenticated && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
