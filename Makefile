UNAME := $(shell uname)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin))
ifeq ($(UNAME),$(filter $(UNAME),Darwin))
OS=darwin
else
OS=linux
endif
else
OS=windows
endif

program_NAME := gamma-test
program_SRCS := $(shell find test -type f -name '*.cpp')
program_OBJS := ${program_SRCS:.cpp=.o}
program_INCLUDE_DIRS := include external/mu/include thirdparty/catch
program_LIBRARY_DIRS :=
program_LIBRARIES :=

CPPFLAGS += $(foreach includedir,$(program_INCLUDE_DIRS),-I$(includedir))
LDFLAGS += $(foreach libdir,$(program_LIBRARY_DIRS),-L$(libdir))
LDFLAGS += $(foreach lib,$(program_LIBRARIES),-l$(lib))

.PHONY: all clean distclean

all: $(program_NAME)

$(program_NAME): $(program_OBJS)
	$(LINK.cc) $(program_OBJS) -o $(program_NAME)

clean:
	@- $(RM) $(program_NAME)
	@- $(RM) $(program_OBJS)

distclean: clean
