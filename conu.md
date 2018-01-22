# conu - Container Utilities

### Objectives - what are we going to implement in python today:

 - run container and delete container
 - check output of container
 - check nginx is running in container
 - mount to container and check files

### Introduction to conu

[conu](https://github.com/fedora-modularity/conu) is a library containing
convenient functions related to containers (and container testing).

For full list of features see [README](https://github.com/fedora-modularity/conu/blob/master/README.md#features)

### Using backend

 - Placeholder for all classes and methods specific for container runtime.
 - Nice way of setting logging level.
 - Now implemented DockerBackend


```python
import logging
from conu import DockerBackend
backend = DockerBackend(logging_level=logging.DEBUG)
```

### Basic example

 - get image:
    - `docker pull 'docker.io/library/nginx'`

```python
image = backend.ImageClass('docker.io/library/nginx')
image.pull()
```

 - run the container
    - `docker run 'docker.io/library/nginx'`
```python
container = image.run_via_binary()
```

 - check container is running
```python
assert container.is_running()
print('Success!')
```

 - stop and delete the container
    - `docker stop $CONTAINER_ID && docker rm $CONTAINER_ID`
```python
container.stop()
container.delete()
```


 - run container with additional options and custom command
    - DockerRunBuilder - helper for building docker run command - as user would write
    - `docker run 'docker.io/library/nginx' echo 'Hello DevConf.cz 2018!'`
```python
message = 'Hello DevConf.cz 2018!'
run_params = DockerRunBuilder(additional_opts=['--rm'], command=['echo', message])
container = image.run_via_binary(run_params)
```

 - check output of container
```python
assert container.logs().decode('utf-8') == message + '\n'
```

### Play with ports

 - wait for port to be open:
    - periodically try to reach port
    - raise exception when port not reached in time limit (default is for 10 seconds)

```python
port = 80
container.wait_for_port(port, timeout=20)
```

 - check everything is as expected:
    - get http response
    - check http response is success
    - check text of http response

```python
http_response = container.http_request(port=port)
assert http_response.ok
assert '<h1>Welcome to nginx!</h1>' in http_response.text
```


### Play with filesystems

 - superuser is required
 - mount container file system and look around
    - check presence of nginx configuration file
    - check presence of default index page
    - read default index page and check the text is as expected

```python
with container.mount() as fs:
    assert fs.file_is_present('/etc/nginx/nginx.conf')
    index_path = '/usr/share/nginx/html/index.html'
    assert fs.file_is_present(index_path)
    index_text = fs.read_file('/usr/share/nginx/html/index.html')
    assert '<h1>Welcome to nginx!</h1>' in index_text
```
