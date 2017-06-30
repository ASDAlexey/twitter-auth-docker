#!/bin/bash
echo "\n\033[1;m Generating .htpasswd file... \033[0m"
echo "\n\033[1;m $(pwd)/nginx/configs/.htpasswd \033[0m"
HASH="$(openssl passwd -apr1 $HTTP_PASSWORD)"
echo "$APP_NAME:$HASH" > $(pwd)/nginx/configs/.htpasswd
echo "\n\033[1;m Generating nginx config file... \033[0m"
ROOT_PATH="$(if [ $NODE_ENV = "prod" ]; then
			    echo " /var/www/$APP_NAME/public/assets"
            else
                if [ $NODE_ENV = "release" ]; then
			        echo " /var/www/$APP_NAME/public/assets"
                else
			        echo " /var/www/$APP_NAME/public"
                fi;
			fi;)"
cat <<EOF > nginx/configs/conf.d/$APP_NAME.conf
upstream php {
	server app:9000;
}
upstream backend {
	server backend:3000;
}
server {
	server_name www.$SERVER_NAME;
	return 301 https://$SERVER_NAME\$request_uri;
}
server {
	listen 80;
	listen 443 ssl;
	ssl_certificate /etc/nginx/ssl/$SERVER_NAME.cert;
	ssl_certificate_key /etc/nginx/ssl/$SERVER_NAME.key;
	auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;

	if (\$scheme = http) {
	    return 301 https://\$server_name\$request_uri;
	}

	server_name $SERVER_NAME;
	root /var/www/$APP_NAME;

    # cache files
	open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # SSL cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # prevent users from opening in an iframe
    add_header X-Frame-Options SAMEORIGIN;

    # prevent hacker scanners
    if ( \$http_user_agent ~* (nmap|nikto|wikto|sf|sqlmap|bsqlbf|w3af|acunetix|havij|appscan) ) {
        return 403;
    }

	location / {
		proxy_pass http://backend;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_set_header Accept-Encoding "";
		proxy_set_header Proxy "";
		add_header 'Cache-Control' 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
		expires off;
    }

    location ~* ^.+\.(jpg|jpeg|gif|png|ico|css|bmp|js|html|htm|svg|eot|ttf|woff|woff2)$ {
        root $ROOT_PATH;
        expires max;
        log_not_found off;
    }
}

server {
	server_name www.admin.$SERVER_NAME;
	return 301 https://admin.$SERVER_NAME\$request_uri;
}
server {
	listen 80;
	listen 443 ssl;
	ssl_certificate /etc/nginx/ssl/$SERVER_NAME.cert;
	ssl_certificate_key /etc/nginx/ssl/$SERVER_NAME.key;

	if (\$scheme = http) {
	    return 301 https://\$server_name\$request_uri;
	}

	server_name admin.$SERVER_NAME;
	root /var/www/html;

	set \$my_var 0;
    if (\$request_uri ~ '^/wp-json/wp/v2/.*') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '^/wp-content/.*') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '/wp-admin?/\$') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '/wp-login.php') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '/wp-login.php') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '/wp-admin/.*.php|css|js') {
      set \$my_var 1;
    }
    if (\$request_uri ~ '^/robots.txt$') {
      set \$my_var 1;
    }
    if (\$my_var !~ 1) {
      return 301  https://\$server_name/wp-admin/;
    }

	location / {
		index index.php;
		try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location = /favicon.ico {
		log_not_found off;
		access_log off;
    }

	location = /robots.txt {
       add_header Content-Type text/plain;
       return 200 "User-agent: *\nDisallow: /\n";
    }

	location ~ \.php\$ {
		fastcgi_intercept_errors on;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		include fastcgi_params;
		fastcgi_pass php;
    }
}
EOF