UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
	ifeq ($(UNAME),$(filter $(UNAME),Darwin))
		XCODE_BASE=$(shell xcode-select -p)

		PLATFORM=MacOSX
		SDK=MacOSX10.10

		PLATFORM_BASE=${XCODE_BASE}/Platforms/${PLATFORM}.platform
		SYSROOT=${PLATFORM_BASE}/Developer/SDKs/${SDK}.sdk

		CXXFLAGS += -stdlib=libc++ -isysroot ${SYSROOT}
		LDFLAGS += -framework OpenGL -framework CoreVideo -framework Cocoa
		OBJCXXFLAGS += -fobjc-arc -fobjc-link-runtime -mmacosx-version-min=10.9

		# TODO: Check for iOS build flags.
		OS=osx
	else
		OS=linux
	endif
	CXXFLAGS += -std=c++11
else
	OS=windows
endif

program_NAME := astro-graphics-tests
program_SRCS := $(shell find test -type f -name '*.cpp' -depth 1)
program_SRCS += $(shell find test/$(OS) -type f \( -name "*.cpp" -or -name "*.mm" \))
program_OBJS := ${program_SRCS:.cpp=.o}
program_OBJS := ${program_OBJS:.mm=.o}
program_DEPS := ${program_OBJS:.o=.dep}
program_INCLUDE_DIRS := include deps
program_LIBRARY_DIRS :=
program_LIBRARIES :=

CXXFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir))
LDFLAGS += $(foreach libdir,$(program_LIBRARY_DIRS),-L$(libdir))
LDFLAGS += $(foreach lib,$(program_LIBRARIES),-l$(lib))

CXXFLAGS += -g -O0

.PHONY: all clean distclean

all: generate_linter_flags $(program_NAME)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -x c++ -MM -MT $@ -MF $(patsubst %.o,%.dep,$@) $<
	$(CXX) $(CXXFLAGS) -x c++ -c -o $@ $<

%.o: %.mm
	$(CXX) $(CXXFLAGS) $(OBJCXXFLAGS) -x objective-c++ -MM -MT $@ -MF $(patsubst %.o,%.dep,$@) $<
	$(CXX) $(CXXFLAGS) $(OBJCXXFLAGS) -x objective-c++ -c -o $@ $<

$(program_NAME): $(program_OBJS)
	$(LINK.cc) $(LDFLAGS) $(program_OBJS) -o $(program_NAME)

generate_linter_flags: Makefile
	echo "$(CXXFLAGS) $(OBJCXXFLAGS)" | tr ' ' '\n' > .linter-clang-flags

clean:
	@- $(RM) $(program_NAME)
	@- $(RM) $(shell find test -type f -name '*.o')
	@- $(RM) $(shell find test -type f -name '*.dep')

distclean: clean

-include $(program_DEPS)
