/proc/[pid]/ns 指向不同namespace号的文件
$$ 是shell中表示当前运行的进程ID号

只包含镜像ID和仓库名
docker images --format "{{.ID}}:{{.Repository}}"

格式输出
docker images --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}"

列出centos镜像的ID
docker images -q centos

所有退出的容器ID
docker ps -qf status=exited

docker rm $(docker ps -qf status=exited)

Dockerfile中
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD ["redis-server"]

注意
要执行的脚本 加执行权限 chmod 755 .sh
ENTRYPOINT 是docker容器执行时要运行的脚本 后边CMD 为默认的参数

docker run -it --rm redis
即 docker容器执行时 运行 docker-entrypoint.sh redis-server

docker run -it --rm redis id
当在容器运行时 在docker run 后添加额外的参数 则覆盖Dockerfile中CMD中指定启动命令


# 建立 redis 用户，并使用 gosu 换另一个用户执行命令
RUN groupadd -r redis && useradd -r -g redis redis
# 下载 gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
# 设置 CMD，并以另外的用户执行
CMD [ "exec", "gosu", "redis", "redis-server" ]



Shell

set -- "$X"就是把X的值返回给$1, set -- $X就是把X作为一个表达式的值一一返回
说明：set --是根据分隔符IFS，把值依次赋给$1,$2,$3，例子2就是展示这个。
变量	含义
$0		当前脚本的文件名
$n		传递给脚本或函数的参数。n 是一个数字，表示第几个参数。例如，第一个参数是$1，第二个参数是$2。
$#		传递给脚本或函数的参数个数。
$*		传递给脚本或函数的所有参数。
$@		传递给脚本或函数的所有参数。被双引号(" ")包含时，与 $* 稍有不同，下面将会讲到。
$?		上个命令的退出状态，或函数的返回值。一般情况下，大部分命令执行成功会返回 0，失败返回 1。
$$		当前Shell进程ID。对于 Shell 脚本，就是这些脚本所在的进程ID。


$* 和 $@ 的区别
$* 和 $@ 都表示传递给函数或脚本的所有参数，不被双引号(" ")包含时，都以"$1" "$2" … "$n" 的形式输出所有参数。
但是当它们被双引号(" ")包含时，"$*" 会将所有的参数作为一个整体，以"$1 $2 … $n"的形式输出所有参数；"$@" 会将各个参数分开，以"$1" "$2" … "$n" 的形式输出所有参数。




































