UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
	ifeq ($(UNAME),$(filter $(UNAME),Darwin))
		# TODO: Check for iOS build flags.
		OS=osx
	else
		OS=linux
	endif
	CXXFLAGS += -std=c++11
else
	OS=windows
endif

program_NAME := gamma-test
program_SRCS := $(shell find test -type f -name '*.cpp' -depth 1)
program_SRCS += $(shell find test/$(OS) -type f \( -name "*.cpp" -or -name "*.mm" \))
program_OBJS := ${program_SRCS:.cpp=.o}
program_OBJS := ${program_OBJS:.mm=.o}
program_DEPS := ${program_OBJS:.o=.dep}
program_INCLUDE_DIRS := include external/mu/include external/mu/external/catch
program_LIBRARY_DIRS :=
program_LIBRARIES :=

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir))
LDFLAGS += $(foreach libdir,$(program_LIBRARY_DIRS),-L$(libdir))
LDFLAGS += $(foreach lib,$(program_LIBRARIES),-l$(lib))

CXXFLAGS += -g -O0

ifeq ($(OS),$(filter $(OS),osx ios))
	CXXFLAGS += -stdlib=libc++
	LDFLAGS +=
endif

.PHONY: all clean distclean

all: submodule_check $(program_NAME)

%.o: %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -x c++ -MM -MT $@ -MF $(patsubst %.o,%.dep,$@) $<
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -x c++ -c -o $@ $<

%.o: %.mm
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -x objective-c++ -MM -MT $@ -MF $(patsubst %.o,%.dep,$@) $<
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -x objective-c++ -c -o $@ $<

submodule_pull:
	$(MAKE) -f Makefile.git submodule_pull

submodule_update:
	$(MAKE) -f Makefile.git submodule_update

submodule_check:
	$(MAKE) -f Makefile.git submodule_check

submodules:
	$(MAKE) -f Makefile.git submodules

$(program_NAME): $(program_OBJS)
	$(LINK.cc) $(program_OBJS) -o $(program_NAME)

clean:
	@- $(RM) $(program_NAME)
	@- $(RM) $(program_OBJS)

distclean: clean

-include $(program_DEPS)
