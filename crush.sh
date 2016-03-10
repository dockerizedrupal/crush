#!/usr/bin/env bash

DEBUG="0"

if [ "${#}" -ne 0 ]; then
  ARGUMENTS=()

  while [ "${1}" != "" ]; do
    ARGUMENT="${1}"

    shift

    case "${ARGUMENT}" in
      "--debug")
        DEBUG="1";
        ;;
      *)
        ARGUMENTS+=("${ARGUMENT}")
        ;;
    esac
  done

  set "${ARGUMENTS[@]}" > /dev/null 2>&1
fi

VERSION="1.1.5"

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Crush version: ${VERSION}"
fi

WORKING_DIR="$(pwd)"

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Working directory: ${WORKING_DIR}"
fi

hash docker 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "crush: docker command not found."

  exit 1
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Docker version: $(echo $(docker --version) | sed 's/Docker version //')"
fi

hash docker-compose 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "crush: docker-compose command not found."

  exit 1
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Docker Compose version: $(echo $( docker-compose --version) | sed 's/docker-compose version //')"
fi

help() {
  cat << EOF
Version: ${VERSION}

Usage: crush

Options:
  -f, --file FILE   Specify an alternate compose file (default: docker-compose.yml)
  -v, --version     Show version number
  -h, --help        Show help
EOF

  exit 1
}

version() {
  help
}

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
  help
fi

if [ "${1}" == "-v" ] || [ "${1}" == "--version" ]; then
  version
fi

DOCKER_COMPOSE_FILE="docker-compose.yml"

if [ "${1}" == "-f" ] || [ "${1}" == "--file" ]; then
  DOCKER_COMPOSE_FILE="${2}"

  set "${@:1}" > /dev/null 2>&1
  set "${@:2}" > /dev/null 2>&1
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Docker Compose file: ${DOCKER_COMPOSE_FILE}"
fi

php_container_exists() {
  local PROJECT_ROOT="${1}"

  echo "$(cd ${PROJECT_ROOT} && docker-compose -f "${DOCKER_COMPOSE_FILE}" ps php 2> /dev/null | grep _php_ | awk '{ print $1 }')"
}

apache_container_exists() {
  local PROJECT_ROOT="${1}"

  echo "$(cd ${PROJECT_ROOT} && docker-compose -f "${DOCKER_COMPOSE_FILE}" ps apache 2> /dev/null | grep _apache_ | awk '{ print $1 }')"
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

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Project root: ${PROJECT_ROOT}"
fi

if [ -z "${PROJECT_ROOT}" ]; then
  echo "crush: ${DOCKER_COMPOSE_FILE} file not found."

  exit 1
fi

PHP_CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: PHP container name: ${PHP_CONTAINER}"
fi

if [ -z "${PHP_CONTAINER}" ]; then
  read -p "crush: PHP container could not be found. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

  PHP_CONTAINER="$(php_container_exists ${PROJECT_ROOT})"

  echo "crush: Waiting for PHP service to come up..."

  sleep 30
elif [ -z "$(php_container_running ${PHP_CONTAINER})" ]; then
  read -p "crush: PHP container is not running. Would you like to start the containers? [Y/n]: " ANSWER

  if [ "${ANSWER}" == "n" ]; then
    exit
  fi

  cd "${PROJECT_ROOT}"

  docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d

  echo "crush: Waiting for PHP service to come up..."

  sleep 30
fi

DRUPAL_ROOT="$(drupal_8_path)"

if [ -z "${DRUPAL_ROOT}" ]; then
  DRUPAL_ROOT="$(drupal_7_path)"

  if [ -z "${DRUPAL_ROOT}" ]; then
    DRUPAL_ROOT="$(drupal_6_path)"
  fi
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Drupal root: ${DRUPAL_ROOT}"
fi

APACHE_CONTAINER="$(apache_container_exists ${PROJECT_ROOT})"

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Apache container name: ${APACHE_CONTAINER}"
fi

DOCUMENT_ROOT=$(docker inspect "${APACHE_CONTAINER}" | grep DOCUMENT_ROOT | grep -Po 'DOCUMENT_ROOT=\K[^"]*')

if [ -z "${DOCUMENT_ROOT}" ]; then
  DOCUMENT_ROOT="/apache/data"
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Document root: ${DOCUMENT_ROOT}"
fi

if [ -n "${DRUPAL_ROOT}" ]; then
  RELATIVE_PATH="${WORKING_DIR/${DRUPAL_ROOT}}"

  if [ "${RELATIVE_PATH:0:1}" == '/' ]; then
    RELATIVE_PATH="$(echo "${RELATIVE_PATH}" | cut -c 2-)"
  fi

  PROJECT_WORKING_DIRECTORY="${DOCUMENT_ROOT}/${RELATIVE_PATH}"
else
  PROJECT_WORKING_DIRECTORY="${DOCUMENT_ROOT}"
fi

if [ "${DEBUG}" == "1" ]; then
  echo "[ DEBUG ] crush: Project working directory: ${PROJECT_WORKING_DIRECTORY}"
fi

ARGS="${@}"

case "${1}" in
  archive-dump|ard|archive-backup|arb)
    if [ -t 0 ]; then
      docker exec -it "${PHP_CONTAINER}" /bin/su - container -lc "cd ${DOCUMENT_ROOT} && drush ${ARGS} --destination=./archive.tar.gz"
    else
      docker exec -i "${PHP_CONTAINER}" /bin/su - container -lc "cd ${DOCUMENT_ROOT} && drush ${ARGS} --destination=./archive.tar.gz"
    fi
  ;;
  archive-restore|arr)
    if [ -t 0 ]; then
      docker exec -it "${PHP_CONTAINER}" /bin/su - container -lc "cd ${DOCUMENT_ROOT} && drush ${ARGS} ./archive.tar.gz"
    else
      docker exec -i "${PHP_CONTAINER}" /bin/su - container -lc "cd ${DOCUMENT_ROOT} && drush ${ARGS} ./archive.tar.gz"
    fi
  ;;
  *)
    if [ -t 0 ]; then
      docker exec -it "${PHP_CONTAINER}" /bin/su - container -lc "cd ${PROJECT_WORKING_DIRECTORY} && drush ${ARGS}"
    else
      docker exec -i "${PHP_CONTAINER}" /bin/su - container -lc "cd ${PROJECT_WORKING_DIRECTORY} && drush ${ARGS}"
    fi
  ;;
esac

cd "${WORKING_DIR}"
