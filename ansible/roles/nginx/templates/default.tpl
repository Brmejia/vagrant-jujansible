server {
    listen  {{ item.listen_port }};

    root {{ item.www_root }};
    index {{ item.index_files | join(" ") }};

    server_name {{ item.server_name }};

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    access_log /var/log/nginx/{{ item.server_name }}.access.log;
    error_log /var/log/nginx/{{ item.server_name }}.error.log;

    error_page 404 /404.html;

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        root /usr/share/nginx/www;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
