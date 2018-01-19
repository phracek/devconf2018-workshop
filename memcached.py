import pexpect
from avocado import main
from avocado.core import exceptions
from moduleframework import module_framework
from moduleframework import common
import time


class SanityCheck1(module_framework.AvocadoTest):
    """
    :avocado: enable
    """

    def test_connection(self):
        self.start()
        session = pexpect.spawn("telnet %s %s " % (self.ip_address,self.getConfig()['service']['port']))
        session.sendline('set Test 0 100 4\r\n\n')
        session.sendline('JournalDev\r\n\n')
        common.print_info("Expecting STORED")
        session.expect('STORED')
        common.print_info("STORED was catched")
        session.close()

    def test_binary(self):
        self.start()
        self.run("ls /usr/bin/memcached")

if __name__ == '__main__':
    main()
