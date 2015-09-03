#!/usr/bin/env bats

DOCKER_COMPOSE_FILE="${BATS_TEST_DIRNAME}/php-5.5_drupal_8.yml"

container() {
  echo "$(docker-compose -f ${DOCKER_COMPOSE_FILE} ps php | grep php | awk '{ print $1 }')"
}

setup_drupal() {
  docker exec "$(container)" /bin/su - container -lc "wget http://ftp.drupal.org/files/projects/drupal-8.0.0-beta14.tar.gz -O /tmp/drupal-8.0.0-beta14.tar.gz"
  docker exec "$(container)" /bin/su - container -lc "tar xzf /tmp/drupal-8.0.0-beta14.tar.gz -C /tmp"
  docker exec "$(container)" /bin/su - container -lc "rsync -avz /tmp/drupal-8.0.0-beta14/ /apache/data"
  docker exec "$(container)" /bin/su - container -lc "cp /apache/data/sites/default/default.services.yml /apache/data/sites/default/services.yml"
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

@test "php-5.5: drupal 8" {
  run /bin/bash -c "${BATS_TEST_DIRNAME}/../crush.sh -f ${DOCKER_COMPOSE_FILE} status | grep 'Drupal bootstrap'"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Successful"* ]]
}
