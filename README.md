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

## Usage

To run composer:

`docker run --rm -ti \
    -v $PWD:/var/www/app \
    --env PGID=$(id -g) \
    --env PUID=$(id -u)  \
    travissouth/workspace \
    composer`

To list other commands:

`docker run --rm -ti \
    -v $PWD:/var/www/app \
    --env PGID=$(id -g) \
    --env PUID=$(id -u) \
    travissouth/workspace`
