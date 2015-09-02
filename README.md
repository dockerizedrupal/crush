# Crush

Version agnostic wrapper around Drush that allows you to use Drush seamlessly 
with Docker containers.

## Install

    TMP="$(mktemp -d)" \
      && git clone https://github.com/dockerizedrupal/crush.git "${TMP}" \
      && sudo cp "${TMP}/crush.sh" /usr/local/bin/crush \
      && sudo chmod +x /usr/local/bin/crush
  
## License

**MIT**
