#  
# TiVoRemote.app Makefile
#
#-ObjC -framework CoreFoundation -framework Foundation \
##		  -framework UIKit -framework LayerKit -framework Coregraphics -framework OfficeImport


CC=arm-apple-darwin-gcc
CFLAGS=-O3
CPPFLAGS=-I/usr/local/arm-apple-darwin/include
LD=$(CC)
LDFLAGS=-L$(HEAVENLY)/usr/lib -L/usr/local/lib/gcc/arm-apple-darwin/4.0.1 \
	-lz -lobjc -lgcc -framework CoreFoundation -framework Foundation \
	-framework UIKit -framework LayerKit -framework CoreGraphics \
	-framework GraphicsServices -framework OfficeImport -lcrypto

SOURCES=$(wildcard source/*.m)
OBJECTS=$(patsubst source/%,obj/%, \
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES))))

IMAGES=$(wildcard images/*.png)

METADATA=$(wildcard metadata/*.xml)


QUIET=true

ifeq ($(QUIET),true)
	QC	= @echo "Compiling [$@]";
	QD	= @echo "Computing dependencies [$@]";
	QL	= @echo "Linking   [$@]";
	QN	= > /dev/null 2>&1
else
	QC	=
	QD	=
	QL	= 
	QN	=
endif

all:    TiVoRemote


# pull in dependency info for *existing* .o files
# this needs to be done after the default target is defined (to avoid defining a meaningless default target)
-include $(OBJECTS:.o=.d)

test:
	echo $(OBJECTS)
	
bundle: TiVoRemote.app

TiVoRemote: obj/TiVoRemote

obj/TiVoRemote:  $(OBJECTS)
	$(QL)$(LD) $(LDFLAGS) -v -o $@ $^ $(QN)

# more complicated dependency computation, so all prereqs listed
# will also become command-less, prereq-less targets
#   sed:    put the real target (obj/*.o) in the dependency file
#   sed:    strip the target (everything before colon)
#   sed:    remove any continuation backslashes
#   fmt -1: list words one per line
#   sed:    strip leading spaces
#   sed:    add trailing colons
obj/%.o:    source/%.m
	@mkdir -p obj
	$(QC)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	$(QD)$(CC) -MM -c $(CFLAGS) $(CPPFLAGS) $<  > obj/$*.d
	@cp -f obj/$*.d obj/$*.d.tmp
	@sed -e 's|.*:|obj/$*.o:|' < obj/$*.d.tmp > obj/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < obj/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> obj/$*.d
	@rm -f obj/$*.d.tmp

clean:
	rm -rf obj TiVoRemote.app TiVoRemote-*.tbz TiVoRemote-*.zip


obj/Info.plist: Info.plist.tmpl
	@echo "Building Info.plist for version 0.20."
	@sed -e 's|__VERSION__|0.20|g' < $< > $@

//TiVoRemote.app: obj/TiVoRemote obj/Info.plist $(IMAGES)
TiVoRemote.app: obj/TiVoRemote obj/Info.plist $(IMAGES) $(METADATA)
	@echo "Creating application bundle."
	@rm -fr TiVoRemote.app
	@mkdir -p TiVoRemote.app
	cp $^ TiVoRemote.app/
	
deploy: obj/TiVoRemote
	scp obj/TiVoRemote root@iphone:/Applications/TiVoRemote.app/
	#ssh iphone chmod +x /Applications/TiVoRemote.app/TiVoRemote

deploy-app: bundle
	scp -r TiVoRemote.app root@iphone:/Applications/

package: bundle
	zip -y -r9 $(ARCHIVE) TiVoRemote.app
