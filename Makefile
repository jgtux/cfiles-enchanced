CC ?= cc

NCURSES_CFLAGS := `pkg-config --cflags ncursesw`
NCURSES_LIBS := `pkg-config --libs ncursesw`

CFLAGS ?= -O2 -Wall
CFLAGS += $(NCURSES_CFLAGS) -MMD -MP

LDFLAGS += -Wl,-z,relro,-z,now -Wl,-z,noexecstack
LDLIBS  += $(NCURSES_LIBS)

SRCS = cf.c
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)
PROG = cfiles

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SCRIPTDIR = $(PREFIX)/share/cfiles/scripts
MANDIR = $(PREFIX)/share/man

BINDIR = $(DESTDIR)/$(BINDIR)
MANDIR = $(DESTDIR)/$(MANDIR)
SCRIPTDIR = $(DESTDIR)/$(SCRIPTDIR)

.PHONY: all clean install uninstall

all: $(PROG)

$(PROG): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LDLIBS)

-include $(DEPS)

clean:
	rm -f $(OBJS) $(DEPS) $(PROG) *~

install:
	install -Dm 755 $(PROG) $(BINDIR)/$(PROG)
	install -Dm 755 scripts/clearimg $(SCRIPTDIR)/clearimg
	install -Dm 755 scripts/displayimg $(SCRIPTDIR)/displayimg
	install -Dm 755 scripts/displayimg_uberzug $(SCRIPTDIR)/displayimg_uberzug
	install -Dm 755 scripts/clearimg_uberzug $(SCRIPTDIR)/clearimg_uberzug
	install -Dm 644 cfiles.1 $(MANDIR)/man1/cfiles.1

uninstall:
	rm -f $(BINDIR)/$(PROG)
	rm -f $(SCRIPTDIR)/clearimg
	rm -f $(SCRIPTDIR)/clearimg_uberzug
	rm -f $(SCRIPTDIR)/displayimg_uberzug
	rm -f $(SCRIPTDIR)/displayimg
	rm -f $(MANDIR)/man1/cfiles.1
