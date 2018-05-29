FROM travissouth/baseimage

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
    echo "export PATH=${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# Source the bash
RUN . ~/.bashrc
ENV PATH ${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin

USER daker

RUN echo "export PATH=${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin" >> ~/.bashrc
RUN . ~/.bashrc
ENV PATH ${PATH}:/var/www/vendor/bin:/usr/local/bin:/home/daker/.composer/vendor/bin
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
    drupal/coder \
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
RUN nodejs --version && \
    npm --version

# Install Yarn
USER root
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    install_clean yarn && \
    yarn --version
USER daker
RUN yarn --version

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
RUN . ~/.bashrc && \
    aws --version

# Install Wodby CLI
USER root
RUN install_clean wget && \
    export WODBY_CLI_LATEST_URL=$(curl -s https://api.github.com/repos/wodby/wodby-cli/releases/latest | grep linux-amd64 | grep browser_download_url | cut -d '"' -f 4) && \
    wget -qO- "${WODBY_CLI_LATEST_URL}" | tar xz -C /usr/local/bin
USER daker
RUN wodby --help

###
USER root
COPY workspace-list /usr/local/bin/workspace-list
RUN chmod +x /usr/local/bin/workspace-list
CMD ["/usr/local/bin/workspace-list"]

# Clean up APT when done.
USER root
RUN apt-get update -y && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
