#!/bin/bash
set -eo pipefail


if [[ -f "/etc/nginx/sites-available/${DOMAIN}" ]]; then
    echo "nginx has already created the basic site"
    certbot_has_already_run=$(grep "listen 443 ssl; # managed by Certbot" "/etc/nginx/sites-available/${DOMAIN}")
    if [ ! -z "$certbot_has_already_run" ]; then
        echo "certbot has already configured a cert. bailing."
        exit 0
    fi
fi

# install some basic dependencies
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y

# set up nginx
sudo mkdir -p /var/www/${DOMAIN}/html
sudo chown -R ${USERNAME}:${USERNAME} /var/www/${DOMAIN}/html
sudo chmod -R 755 /var/www/${DOMAIN}
echo "placeholder" > /var/www/${DOMAIN}/html/index.html

cat > ~/nginx-config <<EOL
server {
    root /var/www/spacemetaphor.com/html;

    index index.html;

    server_name ${DOMAIN} www.${DOMAIN};

    location / {
        proxy_set_header Host \$host;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        proxy_pass http://127.0.0.1:8080;
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        proxy_redirect default;
        proxy_set_header Forwarded for=\$remote_addr;
    }
}
EOL
sudo mv ~/nginx-config /etc/nginx/sites-available/${DOMAIN}


# this command shouldn't error
sudo nginx -t

sudo rm -f /etc/nginx/sites-enabled/${DOMAIN}
sudo ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled
sudo service nginx restart
echo "nginx is now ready to go"

# set up certbot and get a TLS certificate from letsencrypt
sudo certbot --register-unsafely-without-email --agree-tos -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --nginx --redirect
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

