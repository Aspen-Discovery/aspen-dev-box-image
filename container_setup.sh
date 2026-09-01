#!/usr/bin/env bash

ensure_composer() {
    if [ ! -x /usr/local/bin/composer ]; then
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    fi
    (cd /usr/local/aspen-discovery/code/web && /usr/local/bin/composer install --no-interaction --prefer-dist)
}

remap_www_data() {
    groupmod -o -g "${LOCAL_GROUP_ID:-20}" www-data
    usermod -o -u "${LOCAL_USER_ID:-501}" -s /bin/bash www-data
}

create_site_config() {
    local config_dir="$1"
    mkdir -p "${config_dir}"
    if [ -f "${config_dir}/conf/config.ini" ]; then
        echo "Site configuration exists..."
        return 0
    fi
    echo "Creating site configuration in ${config_dir}..."
    (cd /usr/local/aspen-discovery/docker/files/scripts && php createConfig.php "${config_dir}")
}
