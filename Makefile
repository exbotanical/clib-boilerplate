include Makefile.config

.PHONY: all obj install uninstall clean test valgrind lint
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

CFLAGS          := -I$(INCDIR) -I$(DEPSDIR) -Wall -Wextra -pedantic -std=c17
LIBS            := -lm

$(DYNAMIC_TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -shared $(LIBS) -o $(DYNAMIC_TARGET)

$(STATIC_TARGET): $(OBJ)
	$(AR) rcs $@ $(OBJ)

obj/%.o: $(SRCDIR)/%.c $(INCDIR)/$(LIBNAME).h | obj
	$(CC) $< -c $(CFLAGS) -o $@

obj/%.o: $(DEPSDIR)/*/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

$(EXAMPLE_TARGET): $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(EXAMPLEDIR)/main.c $(STATIC_TARGET) $(LIBS) -o $(EXAMPLE_TARGET)

all: $(DYNAMIC_TARGET) $(STATIC_TARGET)

obj:
	mkdir -p obj

install: $(STATIC_TARGET)
	mkdir -p ${LIBDIR} && cp -f ${STATIC_TARGET} ${LIBDIR}/$(STATIC_TARGET)
	mkdir -p ${INCDIR} && cp -r $(INCDIR)/$(LIBNAME).h ${INCDIR}

uninstall:
	rm -f ${LIBDIR}/$(STATIC_TARGET)
	rm -f ${INCDIR}/libys.h

clean:
	rm -f $(OBJ) $(STATIC_TARGET) $(DYNAMIC_TARGET) $(EXAMPLE_TARGET) $(TEST_TARGET)

test: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $(STATIC_TARGET) $(LIBS) -o $(TEST_TARGET)
	./$(TEST_TARGET)
	$(MAKE) clean

valgrind: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $(STATIC_TARGET) $(LIBS) -o $(TEST_TARGET)
	$(VALGRIND) --leak-check=full --track-origins=yes -s ./$(TEST_TARGET)
	$(MAKE) clean

lint:
	$(LINTER) -i $(wildcard $(SRCDIR)/*) $(wildcard $(TESTDIR)/*) $(wildcard $(INCDIR)/*) $(wildcard $(EXAMPLEDIR)/*)
