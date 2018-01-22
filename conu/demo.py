#!/usr/bin/python3
def basics():
    import logging
    from conu import DockerBackend
    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass('nginx')

    container = image.run_via_binary()
    assert container.is_running()
    print('Success!')
    container.delete(force=True)


def check_output():
    import logging
    from conu import DockerBackend, DockerRunBuilder
    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass('nginx')

    # ------------------------------------------------------------
    message = 'Hello!'
    run_params = DockerRunBuilder(command=['echo', message])
    container = image.run_via_binary(run_params)
    assert container.logs().decode('utf-8') == message + '\n'
    #------------------------------------------------------------
    container.delete(force=True)


def check_port():
    import logging
    from conu import DockerBackend, DockerRunBuilder
    backend = DockerBackend(logging_level=logging.DEBUG)
    image = backend.ImageClass('nginx')

    # ------------------------------------------------------------
    port=80
    container = image.run_via_binary()
    container.wait_for_port(port)
    http_response = container.http_request(port=port)
    assert http_response.ok
    assert '<h1>Welcome to nginx!</h1>' in http_response.text
    # ------------------------------------------------------------
    container.delete(force=True)

def check_localhost_port():
    raise NotImplemented
    # run container with -p 80:80 and check port on localhost; might be part of check_port test

def mount_volume():
    raise NotImplemented
    # create directory, make file in it and mount it to container, then check its existence by:
    # mounting filesystem
    # getting content of :/usr/share/nginx/html:ro via http request

def extend_image():
    raise NotImplemented


if __name__ == '__main__':
    mount_volume()