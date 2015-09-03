#!/usr/bin/env bats

DOCKER_COMPOSE_FILE="${BATS_TEST_DIRNAME}/php-5.3_drupal_7.yml"

container() {
  echo "$(docker-compose -f ${DOCKER_COMPOSE_FILE} ps php | grep php | awk '{ print $1 }')"
}

setup_drupal() {
  docker exec "$(container)" /bin/su - container -lc "wget http://ftp.drupal.org/files/projects/drupal-7.39.tar.gz -O /tmp/drupal-7.39.tar.gz"
  docker exec "$(container)" /bin/su - container -lc "tar xzf /tmp/drupal-7.39.tar.gz -C /tmp"
  docker exec "$(container)" /bin/su - container -lc "rsync -avz /tmp/drupal-7.39/ /apache/data"
  docker exec "$(container)" /bin/su - container -lc "drush -r /apache/data -y site-install --db-url=mysqli://root:root@localhost/drupal --account-name=admin --account-pass=admin"
  docker exec "$(container)" /bin/su - container -lc "chown container.container /apache/data"
}

setup() {
  docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

  sleep 10

  setup_drupal
}

teardown() {
  docker-compose -f "${DOCKER_COMPOSE_FILE}" kill
  docker-compose -f "${DOCKER_COMPOSE_FILE}" rm --force
}

@test "php-5.3: drupal 7" {
  run docker exec "$(container)" /bin/su - root -lc "drush -r /apache/data/ status | grep 'Drupal bootstrap'"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Successful"* ]]
}

@test "php-5.3: drupal 7: drush 7" {
  run docker exec "$(container)" /bin/su - root -lc "drush --version"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"7.0.0"* ]]
}

@test "php-5.3: drupal 7: phpcs" {
  run docker exec "$(container)" /bin/su - root -lc "phpcs --version"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"1.5.6"* ]]
}

@test "php-5.3: drupal 7: phpcs: phpcompatibility" {
  run docker exec "$(container)" /bin/su - root -lc "phpcs -i | grep 'PHPCompatibility'"

  [ "${status}" -eq 0 ]
}

@test "php-5.3: drupal 7: phpcs: drupal" {
  run docker exec "$(container)" /bin/su - root -lc "phpcs -i | grep 'Drupal'"

  [ "${status}" -eq 0 ]
}
