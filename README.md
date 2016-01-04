# Crush

Version agnostic wrapper around Drush that allows you to use Drush seamlessly with Docker containers.

This project is part of the [Dockerized Drupal](https://dockerizedrupal.com/) initiative.

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
      && git checkout 1.1.3 \
      && sudo cp "${TMP}/crush.sh" /usr/local/bin/crush \
      && sudo chmod +x /usr/local/bin/crush \
      && sudo ln -s /usr/local/bin/crush /usr/local/bin/drush \
      && cd -

## Tests

Tests are implemented in [Bats: Bash Automated Testing System](https://github.com/sstephenson/bats).

### Test results for the current release

    1..9
    ok 1 crush: php-5.2: drupal 6
    ok 2 crush: php-5.2: drupal 7
    ok 3 crush: php-5.3: drupal 6
    ok 4 crush: php-5.3: drupal 7
    ok 5 crush: php-5.4: drupal 7
    ok 6 crush: php-5.5: drupal 7
    ok 7 crush: php-5.5: drupal 8
    ok 8 crush: php-5.6: drupal 7
    ok 9 crush: php-5.6: drupal 8

## License

**MIT**
