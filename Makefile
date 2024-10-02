include Makefile.config

.PHONY: all obj install uninstall clean test valgrind fmt
.DELETE_ON_ERROR:

PREFIX          := /usr/local
INCDIR          := $(PREFIX)/include
LIBDIR          := $(PREFIX)/lib
SRCDIR          := src
DEPSDIR         := deps
TESTDIR         := t
EXAMPLEDIR      := examples
INCDIR          := include

DYNAMIC_TARGET  := $(LIBNAME).so
STATIC_TARGET   := $(LIBNAME).a
EXAMPLE_TARGET  := example
TEST_TARGET     := test

SRC             := $(wildcard $(SRCDIR)/*.c)
TESTS           := $(wildcard $(TESTDIR)/*.c)
DEPS            := $(filter-out $(wildcard $(DEPSDIR)/libtap/*), $(wildcard $(DEPSDIR)/*/*.c))
TEST_DEPS       := $(wildcard $(DEPSDIR)/libtap/*.c)
OBJ             := $(addprefix obj/, $(notdir $(SRC:.c=.o)) $(notdir $(DEPS:.c=.o)))

INCLUDES        := -I$(INCDIR) -I$(DEPSDIR)
LIBS            :=
CFLAGS          := -Wall -Wextra -pedantic -std=c17 $(INCLUDES)

$(DYNAMIC_TARGET): CFLAGS += -shared
$(DYNAMIC_TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

$(STATIC_TARGET): $(OBJ)
	$(AR) rcs $@ $^

obj/%.o: $(SRCDIR)/%.c $(INCDIR)/$(LIBNAME).h | obj
	$(CC) $< -c $(CFLAGS) -o $@

obj/%.o: $(DEPSDIR)/*/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

$(EXAMPLE_TARGET): $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(LIBS) $(EXAMPLEDIR)/main.c $< -o $@

all: $(DYNAMIC_TARGET) $(STATIC_TARGET)

obj:
	@mkdir -p obj

install: $(STATIC_TARGET)
	@mkdir -p ${LIBDIR} && cp -f ${STATIC_TARGET} ${LIBDIR}/$@
	@mkdir -p ${INCDIR} && cp -r $(INCDIR)/$(LIBNAME).h ${INCDIR}

uninstall:
	@rm -f ${LIBDIR}/$(STATIC_TARGET)
	@rm -f ${INCDIR}/libys.h

clean:
	@rm -f $(OBJ) $(STATIC_TARGET) $(DYNAMIC_TARGET) $(EXAMPLE_TARGET) $(TEST_TARGET)

test: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $< $(LIBS) -o $(TEST_TARGET)
	./$(TEST_TARGET)
	@$(MAKE) clean

valgrind: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $< $(LIBS) -o $(TEST_TARGET)
	$(VALGRIND) --leak-check=full --track-origins=yes -s ./$(TEST_TARGET)
	@$(MAKE) clean

fmt:
	@$(FMT) -i $(wildcard $(SRCDIR)/*) $(wildcard $(TESTDIR)/*) $(wildcard $(INCDIR)/*) $(wildcard $(EXAMPLEDIR)/*)
