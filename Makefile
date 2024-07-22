# snmpb project top-level makefile. Supports Linux, MacOSX, NetBSD & Cygwin/Windows

#    Copyright (C) 2004-2017 Martin Jolicoeur (snmpb1@gmail.com) 

#    This file is part of the SnmpB project 
#    (http://sourceforge.net/projects/snmpb)

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

os := $(shell uname -s)

WINQT_PREFIX = /mingw64/qt5-static/bin/

ifneq ($(findstring BSD,$(os)),)
INSTALL = install
SHARE = share
else
INSTALL = install -v
SHARE = share/apps
endif

ifndef INSTALL_PREFIX
INSTALL_PREFIX = /usr/local
endif

ifndef BIN_PREFIX
BIN_PREFIX = bin
endif

ifndef NO_ROOT
ROOT_OWNER = --owner=root
endif

ifdef QTBIN
QMAKE = $(QTBIN)/qmake
else
QMAKE = qmake
endif

ifneq ($(findstring MINGW,$(os)),)
QMAKE = $(WINQT_PREFIX)qmake
endif

all: snmpb

ifneq ($(findstring MINGW,$(os)),)
LIBSMI = libsmi/win/libsmi.a
else
LIBSMI = libsmi/lib/.libs/libsmi.a
endif

libtomcrypt/libtomcrypt.a:
	$(MAKE) -C libtomcrypt 

libsmi/win/libsmi.a:
	$(MAKE) -C libsmi/win -f Makefile.mingw libs

libsmi/lib/.libs/libsmi.a: libsmi/Makefile
	$(MAKE) -C libsmi

libsmi/Makefile:
ifneq ($(findstring Darwin,$(os)),)
	# MacOSX
	cd libsmi; ./configure --disable-shared --disable-yang --with-pathseparator=';' --with-dirseparator='/' --with-smipath='/Applications/SnmpB.app/Contents/MacOS/mibs;/Applications/SnmpB.app/Contents/MacOS/pibs'
else
	# Linux/BSD
	cd libsmi; ./configure --disable-shared --disable-yang --with-pathseparator=';' --with-dirseparator='/' --with-smipath=$(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs;$(INSTALL_PREFIX)/$(SHARE)/snmpb/pibs
endif

qwt/lib/libqwt.a: qwt/Makefile
	$(MAKE) -C qwt

qwt/Makefile:
	cd qwt; $(QMAKE) qwt.pro

app/makefile.snmpb:
	cd app; $(QMAKE) -o makefile.snmpb snmpb.pro

app/snmpb: app/makefile.snmpb
	$(MAKE) -C app -f makefile.snmpb

snmpb: libtomcrypt/libtomcrypt.a \
       $(LIBSMI) \
       qwt/lib/libqwt.a \
       app/snmpb

clean: app/makefile.snmpb
	-$(MAKE) -C libtomcrypt clean
ifneq ($(findstring MINGW,$(os)),)
	-$(MAKE) -C libsmi/win -f Makefile.mingw clean
else
	-$(MAKE) -C libsmi clean
endif
	-$(MAKE) -C qwt clean
	-$(MAKE) -C app -f makefile.snmpb clean

distclean: clean
ifneq ($(findstring MINGW,$(os)),)
	-$(MAKE) -C libsmi/win -f Makefile.mingw distclean
else
	-$(MAKE) -C libsmi distclean
endif
	-$(MAKE) -C qwt distclean

maintainer-clean: clean
ifneq ($(findstring MINGW,$(os)),)
	-$(MAKE) -C libsmi/win -f Makefile.mingw maintainer-clean
else
	-$(MAKE) -C libsmi maintainer-clean
endif
	-$(MAKE) -C qwt distclean

install:
	$(INSTALL) -d $(INSTALL_PREFIX)/$(BIN_PREFIX) $(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs $(INSTALL_PREFIX)/$(SHARE)/snmpb/pibs
	$(INSTALL) -m 4755 -D -s $(ROOT_OWNER) app/snmpb $(INSTALL_PREFIX)/$(BIN_PREFIX)
	$(INSTALL) -m 444 $(ROOT_OWNER) libsmi/mibs/iana/* $(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs
	$(INSTALL) -m 444 $(ROOT_OWNER) libsmi/mibs/ietf/* $(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs
	$(INSTALL) -m 444 $(ROOT_OWNER) libsmi/mibs/tubs/* $(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs
	$(INSTALL) -m 444 $(ROOT_OWNER) libsmi/pibs/ietf/* $(INSTALL_PREFIX)/$(SHARE)/snmpb/pibs
	$(INSTALL) -m 444 $(ROOT_OWNER) libsmi/pibs/tubs/* $(INSTALL_PREFIX)/$(SHARE)/snmpb/pibs
	rm -f $(INSTALL_PREFIX)/$(SHARE)/snmpb/mibs/Makefile* $(INSTALL_PREFIX)/$(SHARE)/snmpb/pibs/Makefile*
	$(INSTALL) -d $(INSTALL_PREFIX)/share/applications $(INSTALL_PREFIX)/share/mime/packages
	$(INSTALL) -m 444 $(ROOT_OWNER) app/snmpb.desktop $(INSTALL_PREFIX)/share/applications
	$(INSTALL) -m 444 $(ROOT_OWNER) app/snmpb.xml $(INSTALL_PREFIX)/share/mime/packages
	$(INSTALL) -d $(INSTALL_PREFIX)/share/icons/hicolor/128x128/apps $(INSTALL_PREFIX)/share/pixmaps $(INSTALL_PREFIX)/share/icons/hicolor/scalable/apps
	$(INSTALL) -m 444 $(ROOT_OWNER) app/images/snmpb.png $(INSTALL_PREFIX)/share/icons/hicolor/128x128/apps
	$(INSTALL) -m 444 $(ROOT_OWNER) app/images/snmpb.png $(INSTALL_PREFIX)/share/pixmaps
	$(INSTALL) -m 444 $(ROOT_OWNER) app/images/snmpb.svg $(INSTALL_PREFIX)/share/icons/hicolor/scalable/apps
