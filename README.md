# V2ray-ws-tls-With-Bt-Panel
使用说明：

1、目前仅测试过CentOS7，其他系统未经测试；

2、前提：VPS上要安装有 宝塔Linux面板，且通过宝塔安装有Nginx；

3、确保需要使用的域名已经解析至VPS；

4、如果通过宝塔部署了要使用的域名的网站，请先开启SSL；如果没有部署要使用域名的网站，脚本会自行配置；

5、使用本脚本即可完成部署；

6、后续计划：调整伪装的静态网站，添加对UUID、内部监听端口、以及伪装路径的修改……

 

注1：
配合使用 chiakge / Linux-NetSpeed 可以获得更好的加速

wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh
./tcp.sh

 
写在最后：
网络上有很多已经开发多时，比较稳定的部署脚本了，但是由于并不能快速的满足自己的需求，同时为了能够更加有效的利用VPS的资源，而不仅仅是作为一个梯子，所以就花了点时间，对v2ray进行了一些学习，同时参考了一些成熟的脚本思路，自己写了一个适合自己的脚本。不喜勿喷！
