# CLI Docker image for Docksal

This image is focused on console tools necessary to develop LAMP stack applications (namely Drupal and WordPress).

This image(s) is part of the [Docksal](http://docksal.io) image library.

## Docksal Configuration

Set the cli service image to `czietlow/cli:1.2-php7.1`

example:
```
 cli:
    hostname: cli
    image: czietlow/cli:1.2-php7.1
    ports:
      - "2223:22"
    volumes:
      # Project root volume
      - project_root:/var/www:rw
      # Host home volume (for SSH keys and other credentials).
      - host_home:/.home:ro
      # Shared ssh-agent socket
      - docksal_ssh_agent:/.ssh-agent:ro
    environment:
      - HOST_UID=${HOST_UID:-1000}
      - HOST_GID=${HOST_GID:-100}
      - XDEBUG_ENABLED=1
      - XDEBUG_CONFIG=idekey=PHPSTORM remote_host=192.168.64.1
      - PHP_IDE_CONFIG=serverName=${VIRTUAL_HOST}
    dns:
      - ${DOCKSAL_DNS1}
      - ${DOCKSAL_DNS2}
```

## Versions

- `1.2-php7.1`

## Includes

- php
  - php-fpm && php-cli 5.6.x / 7.0.x
  - xdebug
  - composer
  - drush (6,7,8)
    - registry_rebuild
    - coder-8.x + phpcs
  - drupal console launcher
  - wp-cli
- ruby
  - ruby
  - gem
  - bundler
- nodejs
  - nvm
  - nodejs (via nvm)
    - npm
    - bower
- python

Other notable tools:

- git
- curl/wget
- zip/unzip
- mysql-client
- imagemagick
- mc
- mhsendmail

## Xdebug

Xdebug is disabled by default.

To enable it, run the image with `XDEBUG_ENABLED=1`:

```yml
cli
...
  environment:
    ...
    - XDEBUG_ENABLED=1
    ...
```
