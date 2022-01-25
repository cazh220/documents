# FTP服务和SFTP服务搭建

## 一、简介
1. FTP：文件上传下载
2. SFTP:  安全的FTP；如果给指定用户只能访问特定的目录，且不能访问其他目录的权限

## 二、FTP 搭建
1. 准备环境：centos7.6
2. 搭建步骤：
    > a.创建账号
    ```
    useradd -d /var/shtyftp/ -s /sbin/nologin shtyftp
    passwd shtyftp
    修改密码
    ```
    > b.安装vsftpd 
    ```
    yum -y install vsftpd
    ```
    > c.配置vsftpd
    ```
    可以先备份一下配置文件（可选）
    mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
    重新创建一份：grep -v "#" /etc/vsftpd/vsftpd.conf.bak >> /etc/vsftpd/vsftpd.conf
    -------------------------------------------------------------------------------
    修改配置文件如下([vsftpd.conf](../../files/vsftpd.conf))：
    --------------------------------------------------------------------------------
    #是否允许匿名，默认no
    anonymous_enable=NO
    #这个设定值必须要为YES 时，在/etc/passwd内的账号才能以实体用户的方式登入我们的vsftpd主机
    local_enable=YES
    #具有写权限
    write_enable=YES
    #本地用户创建文件或目录的掩码
    local_umask=022
    #当dirmessage_enable=YES时，可以设定这个项目来让vsftpd寻找该档案来显示讯息！您也可以设定其它档名！
    dirmessage_enable=YES
    #当设定为YES时，使用者上传与下载日志都会被纪录起来。记录日志与下一个xferlog_file设定选项有关
    xferlog_enable=YES
    xferlog_std_format=YES
    #上传与下载日志存放路径
    xferlog_file=/var/log/xferlog
    #开启20端口
    connect_from_port_20=YES
    #与上一个设定类似的，只是这个设定针对上传而言！预设是NO。
    ascii_upload_enable=NO
    ascii_download_enable=NO
    #通过搭配能实现以下几种效果：
    #新建用户ftp不能切换目录到上层或其他目录，可以采用以下搭配 
    #①当chroot_list_enable=YES，chroot_local_user=YES时，在/etc/vsftpd.chroot_list文件中列出的用户，可以切换到其他目录；未在文件中列出的用户，不能切换到其他目录。 
    #②当chroot_list_enable=YES，chroot_local_user=NO时，在/etc/vsftpd.chroot_list文件中列出的用户，不能切换到其他目录；未在文件中列出的用户，可以切换到其他目录。 
    #③当chroot_list_enable=NO，chroot_local_user=YES时，所有的用户均不能切换到其他目录。 
    #④当chroot_list_enable=NO，chroot_local_user=NO时，所有的用户均可以切换到其他目录。
    chroot_local_user=NO
    chroot_list_enable=YES
    chroot_list_file=/etc/vsftpd/chroot_list
    #不添加下面这个会报错：500 OOPS: vsftpd: refusing to run with writable root inside chroot()
    allow_writeable_chroot=YES

    #这个是pam模块的名称，我们放置在/etc/pam.d/vsftpd
    pam_service_name=vsftpd
    #当然我们都习惯支持TCP Wrappers的啦！
    tcp_wrappers=YES

    listen=YES
    #启动被动式联机(passivemode)
    pasv_enable=YES
    #上面两个是与passive mode 使用的 port number 有关，如果您想要使用65400到65410 这 11 个 port 来进行被动式资料的连接，可以这样设定
    pasv_min_port=65400
    pasv_max_port=65410

    pasv_address=xxx.xxx.xxx.xxx  # 映射你的公网ip

    #FTP访问目录
    local_root=/var/www/resources/download

    pasv_promiscuous=YES
    ```
    > 创建chroot_list文件
    ```
    cd /etc/vsftpd
    vim chroot_list
    
    #一行一个
    录入账号的名称

    xxx
    xxx
    ```

    > c. 开启入网端口；如果是云服务器必须要开启端口。默认是数据传输端口20和数据传输控制端口21，以及被动模式制定的端口
    > d. 关闭防火墙和selinux设置为disabled
    ```
    systemctl status firewalld  # 查看当前状态
    systemctl stop firewalld
    ```
    > e. 重启vsftpd并设为开机启动
    ```
    systemctl status vsftpd  # 查看状态
    systemctl start vsftpd # 启动

    systemctl enable vsftpd.service # 设为开启启动
    ```
    > f. 如果不能登上，修改验证配置/etc/pam.d/vsftpd
    ```
    session    optional     pam_keyinit.so    force revoke
    auth       required     pam_listfile.so item=user sense=deny file=/etc/vsftpd/ftpusers onerr=succeed
    # 注释掉否则登录不成功
    #auth       required    pam_shells.so
    auth       include      password-auth
    account    include      password-auth
    session    required     pam_loginuid.so
    session    include      password-auth
    ```
3. 访问：
   > ftp xxx.xxx.xxx.xxx
   或者用ftp工具登录

    ------------
    ------------

## 三、SFTP搭建
1. 准备环境：centos7.6
2. 搭建步骤：
    > a.创建账号
    ```
    useradd testuser
    passwd testuser
    # 设置该sftp账号不允许ssh登录
    usermod testuser -s /sbin/nologin
    ```
    > b.修改sftp服务配置文件
    ```
    vim /etc/ssh/sshd_config

    需修改配置信息：
    --------------------------------------------------------
    # override default of no subsystems
    #Subsystem      sftp    /usr/libexec/openssh/sftp-server  #注释掉并修改为下一行

    Subsystem       sftp    internal-sftp
    # Example of overriding settings on a per-user basis
    #Match User anoncvs
    #       X11Forwarding no
    #       AllowTcpForwarding no
    #       PermitTTY no
    #       ForceCommand cvs server

    #UseDNS no
    #AddressFamily inet
    #SyslogFacility AUTHPRIV
    PermitRootLogin yes
    PasswordAuthentication yes

    ################sftp#####
    Match User testuser   #控制的用户账号，也可以为组
    ChrootDirectory /usr/local/java/log #允许用户访问的目录

    ## 此处可以添加多个
    ##Match User testuser2   #控制的用户账号，也可以为组
    ##ChrootDirectory /usr/local/java/log2 #允许用户访问的目录

    X11Forwarding no

    AllowTcpForwarding no

    ForceCommand internal-sftp #指定sftp命令,ssh不可以登录
    ------------------------------------------------------------
    修改完成后：重启sshd
    service sshd restart
    ```
    > c.配置目录权限（这一步非常重要，否则将连不上sftp）
    ```
    # 访问的目录归属用户必须是root
    chmod root:root /usr/local/java/log
    chmod 755 /usr/local/java/log

    ## 修改完成后重启sshd
    ```
3. 访问：
   
   1、命令行
   ```
   sftp testuser@172.0.0.1
   ```
   2.ftp工具选择sftp站点连接(默认端口22)