# git 安装部署（centos7.6）和相关常用命令

1. 安装
```
yum install -y git
```
2. 常用命令
   
|  命令   | 说明  |
|  ----  | ----  |
| git config -l  | 查看当前git配置 |
| git branch -D 分支名  | 删除本地分支 |
| git push origin :分支名  | 删除远端分支（分支名前加：） |
| git push origin :分支名  | 删除远端分支（分支名前加：） |
| git reset --hard commit-id  | 本地代码回滚 |
| git remote add 远端仓库  | 添加远程仓库 |



3. 远端分支回滚步骤
   
1、git checkout the_branch

2、git pull

3、git branch the_branch_backup //备份一下这个分支当前的情况

4、git reset --hard the_commit_id //把the_branch本地回滚到the_commit_id

5、git push origin :the_branch //删除远程 the_branch

6、git push origin the_branch //用回滚后的本地分支重新建立远程分支

7、git push origin :the_branch_backup //如果前面都成功了，删除这个备份分支
