#!/usr/bin/python3

IMAGE_NAME = 'nginx'


def basics():
    import logging
    from conu import DockerBackend

    # prepare backend and image
    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # run container
    container = image.run_via_binary()
    assert container.is_running()
    print('Success!')

    # cleanup
    container.stop()
    container.delete()


def check_output():
    import logging
    from conu import DockerBackend, DockerRunBuilder

    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # run own command in container
    message = 'Hello DevConf.cz 2018!'
    run_params = DockerRunBuilder(command=['echo', message])
    container = image.run_via_binary(run_params)

    # check it went ok
    assert container.logs().decode('utf-8') == message + '\n'
    print('Success!')

    # cleanup
    container.delete(force=True)


def check_port():
    import logging
    from conu import DockerBackend

    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # run container and wait for successful response from port
    port=80
    container = image.run_via_binary()
    container.wait_for_port(port)

    # check response manually
    http_response = container.http_request(port=port)
    assert http_response.ok

    # check nginx runs
    assert '<h1>Welcome to nginx!</h1>' in http_response.text
    print('Success!')

    # cleanup
    container.delete(force=True)


def check_localhost_port():
    import logging
    import time
    from conu import DockerBackend, check_port

    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # publish 8080 port
    container = image.run_via_binary(additional_opts=['-p', '8080:8080'])
    time.sleep(2)

    # check it is published correctly
    check_port(host='localhost', port=8080)
    print('Success!')

    # cleanup
    container.delete(force=True)


def mount_container_filesystem():
    import logging
    from conu import DockerBackend

    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # run nginx container
    container = image.run_via_binary()

    # mount container filesystem
    with container.mount() as fs:
        # check presence of nginx configuration file
        assert fs.file_is_present('/etc/nginx/nginx.conf')

        # check presence of default nginx page
        index_path = '/usr/share/nginx/html/index.html'
        assert fs.file_is_present(index_path)

        # and its text
        index_text = fs.read_file('/usr/share/nginx/html/index.html')
        assert '<h1>Welcome to nginx!</h1>' in index_text
        print(index_text)

    print('Success!')

    # cleanup
    container.delete(force=True)


def self_cleanup():
    import logging
    import pytest
    from conu import DockerBackend, DockerRunBuilder

    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass(IMAGE_NAME)

    # alternative of docker run --rm nginx
    run_params = DockerRunBuilder(additional_opts=['--rm'])
    container = image.run_via_binary(run_params)
    assert container.is_running()

    # check container is removed when stopped
    container.stop()
    with pytest.raises(Exception):
        container.inspect()


if __name__ == '__main__':
    basics()
    check_output()
    check_port()
    check_localhost_port()
    mount_container_filesystem()
    self_cleanup()
