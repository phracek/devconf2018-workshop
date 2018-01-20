# [s2i](https://github.com/openshift/source-to-image)-enabled containerized services

(What a horrible title?!)


We'll be working on this s2i-enabled nginx container image:

```
$ git clone --recursive https://github.com/sclorg/nginx-container
```


## Getting familiar

 * ooooh, more versions
 * `cd 1.12`
 * `s2i/bin`, what's that?
 * `root/opt/app-root`, more weird stuff
 * oh nice, tests, can we run them?
   ```
   cd .. && make check VERSION="1.12" SKIP_SQUASH=1
   ```
 * or
   ```
   cd test && IMAGE_NAME=docker.io/centos/nginx-112-centos7 ./run
   ```


## What is this about again?

We can use `s2i` tool to get our custom configuration/application, get a container image and bake them together.

```
$ s2i build ./test/test-app docker.io/centos/nginx-112-centos7 our-nginx-app
$ docker run -p 8080:8080 --name=ng our-nginx-app
$ curl -q http://0.0.0.0:8080/
```

Let's have a look at the `test-app` first:
```
$ ls -lha test/test-app/
```

Oh cool. I need to use nginx [`upstream`](http://nginx.org/en/docs/http/ngx_http_upstream_module.html) directive for my app.


## Let's make this container image better!

By adding support to override root nginx.conf.


### But first, we need to find it.

```
$ docker exec -ti ng bash

bash-4.2$ rpm -ql $(rpm -qa | grep nginx) | grep conf
/etc/opt/rh/rh-nginx112/pm/config.d
/etc/opt/rh/rh-nginx112/sysconfig
/opt/rh/rh-nginx112/root/usr/share/ghostscript/conf.d
/etc/opt/rh/rh-nginx112/nginx/conf.d
/etc/opt/rh/rh-nginx112/nginx/fastcgi.conf
/etc/opt/rh/rh-nginx112/nginx/fastcgi.conf.default
/etc/opt/rh/rh-nginx112/nginx/nginx.conf
/etc/opt/rh/rh-nginx112/nginx/nginx.conf.default
/opt/rh/rh-nginx112/register.content/etc/opt/rh/rh-nginx112/nginx/fastcgi.conf
/opt/rh/rh-nginx112/register.content/etc/opt/rh/rh-nginx112/nginx/fastcgi.conf.default
/opt/rh/rh-nginx112/register.content/etc/opt/rh/rh-nginx112/nginx/nginx.conf
/opt/rh/rh-nginx112/register.content/etc/opt/rh/rh-nginx112/nginx/nginx.conf.default
```

```
$ docker cp ng:/etc/opt/rh/rh-nginx112/nginx/nginx.conf .
```

And now just edit the assemble script:
```
$ $EDITOR s2i/bin/assemble
```

[For cheaters.](https://github.com/phracek/devconf2018-workshop/blob/master/s2i/0001-minimal-fix.patch)
