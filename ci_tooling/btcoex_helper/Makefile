CC=clang
OUTPUT=../../payloads/Tools/BTCoex/usr/libexec/oclp-btcoex

all: clean release

release: main.m
	$(CC) -fobjc-arc -O2 -framework Foundation -arch x86_64 -mmacosx-version-min=11.0 -o $(OUTPUT) main.m
	/usr/bin/codesign --force --sign - $(OUTPUT)

clean:
	/bin/rm -f $(OUTPUT)
