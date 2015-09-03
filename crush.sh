#!/usr/bin/env bash

WORKING_DIR="$(pwd)"

hash docker 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "crush: docker command not found."

  exit 1
fi

hash docker-compose 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "crush: docker-compose command not found."

  exit 1
fi

version() {
  cat << EOF
Version: 1.0.2
EOF

  exit 1
}

if [ "${1}" == "-v" ] || [ "${1}" == "--version" ]; then
  version
fi

DOCKER_COMPOSE_FILE="docker-compose.yml"

if [ "${1}" == "-f" ] || [ "${1}" == "--file" ]; then
  DOCKER_COMPOSE_FILE="${2}"

  set "${@:1}" > /dev/null 2>&1
  set "${@:2}" > /dev/null 2>&1
fi

php_container_exists() {
  local DRUPAL_ROOT="${1}"

  echo "$(cd ${DRUPAL_ROOT} && docker-compose -f "${DOCKER_COMPOSE_FILE}" ps php 2> /dev/null | grep _php_ | awk '{ print $1 }')"
}

php_container_running() {
  local CONTAINER="${1}"

  echo "$(docker exec ${CONTAINER} date 2> /dev/null)"
}

docker_compose_file_path() {
  local DOCKER_COMPOSE_FILE_PATH=""

  while [ "$(pwd)" != '/' ]; do
    if [ "$(ls "${DOCKER_COMPOSE_FILE}" 2> /dev/null)" == "${DOCKER_COMPOSE_FILE}" ]; then
      DOCKER_COMPOSE_FILE_PATH="$(pwd)"

      break
    fi

    cd ..
  done

  echo "${DOCKER_COMPOSE_FILE_PATH}"
}

drupal_8_path() {
  local DRUPAL_8_PATH=""

  while [ "$(pwd)" != '/' ]; do
    if [ "$(ls index.php 2> /dev/null)" == "index.php" ]; then
      if [ -n "$(cat index.php | grep "^\$autoloader" 2> /dev/null)" ]; then
        DRUPAL_8_PATH="$(pwd)"

        break
      fi
    fi

    cd ..
  done

  echo "${DRUPAL_8_PATH}"
}

drupal_7_path() {
  local DRUPAL_7_PATH=""

  while [ "$(pwd)" != '/' ]; do
    if [ "$(ls index.php 2> /dev/null)" == "index.php" ]; then
      if [ -n "$(cat index.php | grep "^menu_execute_active_handler" 2> /dev/null)" ]; then
        DRUPAL_7_PATH="$(pwd)"

        break
      fi
    fi

    cd ..
  done

  echo "${DRUPAL_7_PATH}"
}

drupal_6_path() {
  local DRUPAL_6_PATH=""

  while [ "$(pwd)" != '/' ]; do
    if [ "$(ls index.php 2> /dev/null)" == "index.php" ]; then
      if [ -n "$(cat index.php | grep "^drupal_page_footer" 2> /dev/null)" ]; then
        DRUPAL_6_PATH="$(pwd)"

        break
      fi
    fi

    cd ..
  done

  echo "${DRUPAL_6_PATH}"
}

PROJECT_ROOT="$(docker_compose_file_path)"

if [ -z "${PROJECT_ROOT}" ]; then
  echo "crush: ${DOCKER_COMPOSE_FILE} file not found."

  exit 1
fi

CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

if [ -z "${CONTAINER}" ]; then
  read -p "crush: PHP container could not be found. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

  CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

  echo "crush: Waiting for PHP service to come up..."

  sleep 10
elif [ -z "$(php_container_running ${CONTAINER})" ]; then
  read -p "crush: PHP container is not running. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

  echo "crush: Waiting for PHP service to come up..."

  sleep 10
fi

DRUPAL_ROOT="$(drupal_8_path)"

if [ -z "${DRUPAL_ROOT}" ]; then
  DRUPAL_ROOT="$(drupal_7_path)"

  if [ -z "${DRUPAL_ROOT}" ]; then
    DRUPAL_ROOT="$(drupal_6_path)"
  fi
fi

DOCUMENT_ROOT="/apache/data"

if [ -n "${DRUPAL_ROOT}" ]; then
  RELATIVE_PATH="${WORKING_DIR/${PROJECT_ROOT}}"

  if [ "${RELATIVE_PATH:0:1}" == '/' ]; then
    RELATIVE_PATH="$(echo "${RELATIVE_PATH}" | cut -c 2-)"
  fi

  PROJECT_WORKING_DIRECTORY="${DOCUMENT_ROOT}/${RELATIVE_PATH}"
else
  PROJECT_WORKING_DIRECTORY="${DOCUMENT_ROOT}"
fi

ARGS="${@}"

if [ -t 0 ]; then
  docker exec -it "${CONTAINER}" /bin/su - container -lc "cd ${PROJECT_WORKING_DIRECTORY} && drush ${ARGS}"
else
  docker exec -i "${CONTAINER}" /bin/su - container -lc "cd ${PROJECT_WORKING_DIRECTORY} && drush ${ARGS}"
fi

cd "${WORKING_DIR}"
