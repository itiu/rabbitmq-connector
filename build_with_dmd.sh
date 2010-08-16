date
rm *.a
dmd -version=Tango /usr/include/d/dmd/tango/net/InternetAddress /usr/include/d/dmd/tango/net/device/Socket /usr/include/d/dmd/tango/stdc/stdarg.d /usr/include/d/dmd/tango/stdc/errno.d -Iimport src/*.d  -oflibrabbitmq_client.a -O -Hdexport -release -lib
rm *.o
date
