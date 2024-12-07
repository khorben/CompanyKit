TARGETS	= $(OBJDIR)shlint.log $(OBJDIR)sysadmin.log
OBJDIR	=
PREFIX	= /usr/local
DESTDIR	=
RM	= rm -f
LN	= ln -f
MKDIR	= mkdir -m 0755 -p
INSTALL	= install


all:

$(OBJDIR)shlint.log: shlint.sh sysadmin.sh ../sysadmin/sysadmin.sh
	./shlint.sh -P "$(PREFIX)" -- "$(OBJDIR)shlint.log"

$(OBJDIR)sysadmin.log: sysadmin.sh ../sysadmin/sysadmin.sh
	./sysadmin.sh -P "$(PREFIX)" -- "$(OBJDIR)sysadmin.log"

clean:
	./shlint.sh -c -P "$(PREFIX)" -- "$(OBJDIR)shlint.log"
	./sysadmin.sh -c -P "$(PREFIX)" -- "$(OBJDIR)sysadmin.log"

distclean: clean
	$(RM) -- $(TARGETS)

install: all

uninstall:

.PHONY: all clean distclean install uninstall
