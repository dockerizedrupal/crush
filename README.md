> **Notice:** *This project is part of the [Dockerized Drupal](https://dockerizedrupal.com/) initiative.*

# Crush

Version agnostic wrapper around Drush that allows you to use Drush seamlessly with Docker containers.

## Usage

    Usage: crush

    Options:
      -f, --file FILE   Specify an alternate compose file (default: docker-compose.yml)
      -v, --version     Show version number
      -h, --help        Show help

## Install

    TMP="$(mktemp -d)" \
      && git clone https://github.com/dockerizedrupal/crush.git "${TMP}" \
      && cd "${TMP}" \
      && git checkout 1.1.5 \
      && sudo cp "${TMP}/crush.sh" /usr/local/bin/crush \
      && sudo chmod +x /usr/local/bin/crush \
      && sudo ln -s /usr/local/bin/crush /usr/local/bin/drush \
      && cd -

## Tests

Tests are implemented in [Bats: Bash Automated Testing System](https://github.com/sstephenson/bats).

### Test results for the current release

    1..18
    ok 1 crush: php-5.2: drupal 6
    ok 2 crush: php-5.2: drupal 6: document root
    ok 3 crush: php-5.2: drupal 7
    ok 4 crush: php-5.2: drupal 7: document root
    ok 5 crush: php-5.3: drupal 6
    ok 6 crush: php-5.3: drupal 6: document root
    ok 7 crush: php-5.3: drupal 7
    ok 8 crush: php-5.3: drupal 7: document root
    ok 9 crush: php-5.4: drupal 7
    ok 10 crush: php-5.4: drupal 7: document root
    ok 11 crush: php-5.5: drupal 7
    ok 12 crush: php-5.5: drupal 7: document root
    ok 13 crush: php-5.5: drupal 8
    ok 14 crush: php-5.5: drupal 8: document root
    ok 15 crush: php-5.6: drupal 7
    ok 16 crush: php-5.6: drupal 7: document root
    ok 17 crush: php-5.6: drupal 8
    ok 18 crush: php-5.6: drupal 8: document root

## License

**MIT**
