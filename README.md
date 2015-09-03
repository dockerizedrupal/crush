# Crush

Version agnostic wrapper around Drush that allows you to use Drush seamlessly with Docker containers.

## Install

    TMP="$(mktemp -d)" \
      && git clone https://github.com/dockerizedrupal/crush.git "${TMP}" \
      && cd "${TMP}" \
      && git checkout 1.0.1 \
      && sudo cp "${TMP}/crush.sh" /usr/local/bin/crush \
      && sudo chmod +x /usr/local/bin/crush
      && cd -

## License

**MIT**
