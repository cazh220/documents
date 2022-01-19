# nodejs环境(centos7.6)安装和部署、npm配置

1. 下载安装包(v16.13.2)
```
wget   https://npmmirror.com/mirrors/node/v16.13.2/node-v16.13.2-linux-x64.tar.gz
```
2. 解压安装包
```
tar -zxvf node-v16.13.2-linux-x64.tar.gz
```
3. 进入文件夹
```
cd node-v16.13.2-linux-x64
```
正常情况下，在bin目录中会有node、npm、npx三个文件 ./node、./npm 可执行

4. 配置node、npm、npx全局环境变量(建立软链接)
```
ln -s /usr/local/src/node-v16.13.2-linux-x64/bin/node /usr/local/bin/node
ln -s /usr/local/src/node-v16.13.2-linux-x64/bin/npm /usr/local/bin/npm
ln -s /usr/local/src/node-v16.13.2-linux-x64/bin/npx /usr/local/bin/npx
```
5. 任务目录皆可用：node -v
   

==================================================================
# npm 配置淘宝镜像
1. 临时配置淘宝镜像
```
npm install --registry https://registry.npm.taobao.org
```
2. 全局使用
```
npm config set registry https://registry.npm.taobao.org
```
3. 查看全局配置
```
npm config get registry
```
4. 恢复默认全局配置
```
npm config set registry https://registry.npmjs.org
```
5. *通过cnpm使用*
```
npm install -g cnpm --registry=https://registry.npm.taobao.org
```
