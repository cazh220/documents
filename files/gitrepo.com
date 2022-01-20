server {
    listen      80;
    server_name git.jsyinghuan.com;
    root /usr/local/doc/git;

    client_max_body_size 400m;

    auth_basic "Git User Authentication";
    auth_basic_user_file /usr/local/nginx/conf/pass.db;

    location ~ ^.*\.git/objects/([0-9a-f]+/[0-9a-f]+|pack/pack-[0-9a-f]+.(pack|idx))$ {
        root /var/www/html;
    }    
    
    location ~ /.*\.git/(HEAD|info/refs|objects/info/.*|git-(upload|receive)-pack)$ {
        root          /usr/local/doc/git;
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        #fastcgi_pass  127.0.0.1:9000;
        fastcgi_connect_timeout 24h;
        fastcgi_read_timeout 24h;
        fastcgi_send_timeout 24h;
        fastcgi_param SCRIPT_FILENAME  /usr/libexec/git-core/git-http-backend; 
        fastcgi_param PATH_INFO         $uri;
        fastcgi_param GIT_HTTP_EXPORT_ALL "";
        fastcgi_param GIT_PROJECT_ROOT  /usr/local/doc/git;
        fastcgi_param REMOTE_USER $remote_user;
        include fastcgi_params;
    }

    try_files $uri @gitweb;

    location @gitweb {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        #fastcgi_pass  127.0.0.1:9000;
        fastcgi_param GITWEB_CONFIG    /etc/gitweb.conf;
        fastcgi_param SCRIPT_FILENAME  /var/www/git/gitweb.cgi;
        fastcgi_param PATH_INFO        $uri;
        include fastcgi_params;
    }
}

