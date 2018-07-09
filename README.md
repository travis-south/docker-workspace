# docker-workspace
Image for my dev tools

## What's inside?
 - Composer
 - travissouth/phpqatools (PHPUnit, Behat, PHPCS, etc.)
 - Drush
 - Laravel Installer
 - NodeJS/NPM
 - Yarn
 - Python/PIP
 - Ansible
 - AWS CLI
 - Wodby CLI
 - ES Lint
 - TS Lint
 - Sonar CLI
 - JMeter
 - Apache Bench
 - Siege

## Usage

### Requirements

1. `sudo` permissions.
1. git
1. docker

### Installation

```shell
bash <(curl https://raw.githubusercontent.com/travis-south/docker-workspace/master/install?no_cache=$RANDOM)
```

### To run composer
```shell
ws composer
```

### To list other commands

```shell
ws
```
