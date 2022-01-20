# git 代码仓库搭建和迁移
## 集成：centos7.6 + nginx + fcgiwrap + spwan-fcgi

> 
1. nginx 安装
2. git 安装
3. spwan-cgi 安装
   ```
   cd /usr/local/src
   git clone https://github.com/lighttpd/spawn-fcgi.git
   cd spawn-fcgi && ./autogen.sh && ./configure && make && make install
   ```
4. fcgi-devel 安装(安装fcgi-devel,注意:需要先安装epel源)
   ```
   yum -y install epel-release
   yum -y install fcgi-devel
   ```
5. fcgiwrap安装
   ```
   cd /usr/local/src
   git clone https://github.com/gnosek/fcgiwrap.git
   cd fcgiwrap && autoreconf -i && ./configure && make && make install 
   ```

---------------------------------
6. 添加git仓库的运行用户，初始化仓库
   ```
   useradd -r -s /sbin/nologin git
   mkdir -p /data/git && cd /data/git
   git init --bare repo.git && chown -R git:git /data/git
   cd repo.git && mv hooks/post-update.sample hooks/post-update
   git update-server-info
   ```
7. 编写fcgiwrap 启动脚本【参考配置文件[fcgiwrap配置文件](../files/fcgiwrap)】
   > 重点修改：注意其中的"FCGI_USER" 和 "FCGI_GROUP" 以及 "FORK_NUM"，分别为fastcgi运行的用户，组以及进程数（按需调整），需要与nginx配置中的worker用户一样。 修改脚本权限，设置开机启动
   ```
   vi /etc/init.d/fcgiwrap
   ```
   ```
   #! /bin/bash
   ### BEGIN INIT INFO
   # Provides:          fcgiwrap
   # Required-Start:    $remote_fs
   # Required-Stop:     $remote_fs
   # Should-Start:
   # Should-Stop:
   # Default-Start:     2 3 4 5
   # Default-Stop:      0 1 6
   # Short-Description: FastCGI wrapper
   # Description:       Simple server for running CGI applications over FastCGI
   ### END INIT INFO

   PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
   SPAWN_FCGI="/usr/local/bin/spawn-fcgi"
   DAEMON="/usr/local/sbin/fcgiwrap"
   NAME="fcgiwrap"

   PIDFILE="/var/run/$NAME.pid"

   FCGI_SOCKET="/var/run/$NAME.socket"
   FCGI_USER="nginx"
   FCGI_GROUP="nginx"
   FORK_NUM=4
   SCRIPTNAME=/etc/init.d/$NAME

    case "$1" in
        start)
            echo -n "Starting $NAME... "

            PID=`pidof $NAME`
            if [ ! -z "$PID" ]; then
                echo " $NAME already running"
                exit 1
            fi

            $SPAWN_FCGI -u $FCGI_USER -g $FCGI_GROUP -s $FCGI_SOCKET -P $PIDFILE -F $FORK_NUM -f $DAEMON

            if [ "$?" != 0 ]; then
                echo " failed"
                exit 1
            else
                echo " done"
            fi
        ;;

        stop)
            echo -n "Stoping $NAME... "

            PID=`pidof $NAME`
            if [ ! -z "$PID" ]; then
                kill `pidof $NAME`
                if [ "$?" != 0 ]; then
                    echo " failed. re-quit"
                    exit 1
                else
                    rm -f $pid
                    echo " done"
                fi
            else
                echo "$NAME is not running."
                exit 1
            fi
        ;;

        status)
            PID=`pidof $NAME`
            if [ ! -z "$PID" ]; then
                echo "$NAME (pid $PID) is running..."
            else
                echo "$NAME is stopped"
                exit 0
            fi
        ;;

        restart)
            $SCRIPTNAME stop
            sleep 1
            $SCRIPTNAME start
        ;;

        *)
            echo "Usage: $SCRIPTNAME {start|stop|restart|status}"
            exit 1
        ;;
    esac
   ```

8. 设置fcgiwrap权限并启动fcgiwrap
   ```
   chmod a+x /etc/init.d/fcgiwrap
   chkconfig --level 35 fcgiwrap on
   /etc/init.d/fcgiwrap start
   ```
   -----
9. 配置代码仓库访问地址，nginx配置
   ```
   cd /usr/local/nginx/conf/servers
   vi gitrepo.com
   ```
10. gitrepo.com配置如下（路径，名称可根据自己项目修改）
    > 配置参考 [gitrepo.com](../files/gitrepo.com)
    ```
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
    ```

11. 修改nginx.conf中worker进程所有者 
    ```
    user nginx; #确保user用户拥有权限调用fastcgi
    worker_processes 1;
    ```    
12. 安装http-tools并添加认证用户（pass.db，nginx访问有认证）
    ```
    yum -y install httpd-tools
    cd /usr/local/nginx/conf
    htpasswd -c pass.db guestUser #确认密码，创建guestUser
    # htpasswd -b pass.db user1 passwd1 #向认证文件中追加用户user1
    # htpasswd -D pass.db user1 #从认证文件中删除指定的用户 
    ```
    ---
13. [可选]配置gitweb
    ```
    find /usr/local/share --name gitweb.cgi
    cd /usr/local/share/gitweb && ll /usr/local/share/gitweb
    vi /etc/git/gitweb.conf
    ```
14. [可选]修改gitweb.conf
    ```
   # path to git projects (<project>.git)
	$projectroot = "/data/git";

	# directory to use for temp files
	$git_temp = "/tmp";

	# target of the home link on top of all pages
	$home_link = $my_uri || "/";

	# html text to include at home page
	$home_text = "indextext.html";

	# file with project list; by default, simply scan the projectroot dir.
	$projects_list = $projectroot;

	# javascript code for gitweb
	$javascript = "static/gitweb.js";

	# stylesheet to use
	$stylesheet = "static/gitweb.css";

	# logo to use
	$logo = "static/git-logo.png";

	# the 'favicon'
	$favicon = "static/git-favicon.png";
    ```

15. 启动nginx和fcgiwrap
   ```
   /usr/local/nginx/sbin/nginx
   /etc/init.d/fcgiwrap start
   ```
16. [可选]权限配置参考<https://blog.csdn.net/wang839305939/article/details/78194944>

----
# git仓库迁移  保留提交记录
### 方法一
   
  >文件整个复制  scp /usr/local/doc/git root@127.0.0.1:/usr/local/doc/git

### 方法二
    
>git命令迁移
```
在新的仓库地址下初始目标空仓库

mkdir test.git
git --bare init 

本地随便找个目录
git clone --bare 旧git仓库地址
进入仓库目录
git push --mirror  新的仓库地址
```





