.ifdef .MAKE
# BSD Make
NCURSES_CFLAGS != pkg-config --cflags ncursesw
NCURSES_LIBS   != pkg-config --libs ncursesw
.else
# GNU Make
NCURSES_CFLAGS := $(shell pkg-config --cflags ncursesw)
NCURSES_LIBS   := $(shell pkg-config --libs ncursesw)
.endif

CC ?= cc

CFLAGS ?= -O2 -Wall
CFLAGS += $(NCURSES_CFLAGS) -MMD -MP

DEBUG_CFLAGS = -O0 -g \
	-Wall -Wextra -Wpedantic -Wshadow -Wconversion \
	-Wcast-align -Wstrict-prototypes -Wmissing-prototypes \
	-Wformat=2 -Wundef -Wwrite-strings \
	-Werror=implicit-function-declaration

LDFLAGS += -Wl,-z,relro,-z,now -Wl,-z,noexecstack
LDLIBS  += $(NCURSES_LIBS)

SRCS = cf.c
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)
PROG ?= cfiles

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SCRIPTDIR = $(PREFIX)/share/$(PROG)/scripts
MANDIR = $(PREFIX)/share/man

.PHONY: all clean install uninstall debug

all: $(PROG)

$(PROG): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LDLIBS)

-include $(DEPS)

clean:
	rm -f $(OBJS) $(DEPS) $(PROG) *~

install: all
	mkdir -p $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(SCRIPTDIR)
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	install -m 755 $(PROG) $(DESTDIR)$(BINDIR)/$(PROG)
	install -m 755 scripts/clearimg $(DESTDIR)$(SCRIPTDIR)/clearimg
	install -m 755 scripts/displayimg $(DESTDIR)$(SCRIPTDIR)/displayimg
	install -m 755 scripts/displayimg_uberzug $(DESTDIR)$(SCRIPTDIR)/displayimg_uberzug
	install -m 755 scripts/clearimg_uberzug $(DESTDIR)$(SCRIPTDIR)/clearimg_uberzug
	install -m 644 cfiles.1 $(DESTDIR)$(MANDIR)/man1/cfiles.1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(PROG)
	rm -f $(DESTDIR)$(SCRIPTDIR)/clearimg
	rm -f $(DESTDIR)$(SCRIPTDIR)/clearimg_uberzug
	rm -f $(DESTDIR)$(SCRIPTDIR)/displayimg_uberzug
	rm -f $(DESTDIR)$(SCRIPTDIR)/displayimg
	rm -f $(DESTDIR)$(MANDIR)/man1/cfiles.1

debug: clean
	$(MAKE) CFLAGS="$(DEBUG_CFLAGS) $(NCURSES_CFLAGS) -MMD -MP"
