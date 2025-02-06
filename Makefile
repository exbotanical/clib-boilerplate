include Makefile.config

.PHONY: all obj install uninstall clean unit_test unit_test_dev valgrind fmt
.DELETE_ON_ERROR:

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

STRICT          := -Wall -Werror -Wextra -Wno-missing-field-initializers \
	-Wmissing-prototypes -Wstrict-prototypes -Wold-style-definition \
 	-Wno-unused-parameter -Wno-unused-function -Wno-unused-value \

INCLUDES        := -I$(INCDIR) -I$(DEPSDIR)
LIBS            :=
CFLAGS          := -Wall -Wextra -pedantic -std=c17 $(INCLUDES)

$(DYNAMIC_TARGET): CFLAGS += -shared
$(DYNAMIC_TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(STRICT) $^ $(LIBS) -o $@

$(STATIC_TARGET): $(OBJ)
	$(AR) rcs $@ $^

obj/%.o: $(SRCDIR)/%.c $(INCDIR)/$(LIBNAME).h | obj
	$(CC) $< -c $(CFLAGS) $(STRICT) -o $@

obj/%.o: $(DEPSDIR)/*/%.c | obj
	$(CC) $< -c $(CFLAGS) $(STRICT) -o $@

$(EXAMPLE_TARGET): $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(EXAMPLEDIR)/main.c $< $(LIBS) -o $@

all: $(DYNAMIC_TARGET) $(STATIC_TARGET)

obj:
	@mkdir -p obj

install: $(INCDIR)/*.h | $(STATIC_TARGET)
	$(shell mkdir -p $(INSTALL_DIR)/lib)
	$(shell mkdir -p $(INSTALL_DIR)/include/$(LIBNAME))
	$(INSTALL) $(STATIC_TARGET) $(INSTALL_DIR)/lib
	# TODO: CHANGE THIS BASED ON SINGLE OR MULT HEADERS
# MULT:
	$(INSTALL) $^ $(INSTALL_DIR)/include/$(LIBNAME)
# SINGLE:
	$(INSTALL) $(LIBNAME).h $(INSTALL_DIR)/include

	$(INSTALL) $(MANPAGE) $(MAN_DIR)/$(MANPAGE)

uninstall:
	$(shell rm $(INSTALL_DIR)/lib/$(STATIC_TARGET))
# MULT:
	$(shell rm -rf $(INSTALL_DIR)/include/$(LIBNAME))
# SINGLE:
	$(shell rm $(INSTALL_DIR)/include/$(LIBNAME).h)
	$(shell rm $(MAN_DIR)/$(MANPAGE))

clean:
	@rm -f $(OBJ) $(STATIC_TARGET) $(DYNAMIC_TARGET) $(EXAMPLE_TARGET) $(TEST_TARGET)

unit_test: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $(STATIC_TARGET) -I$(SRCDIR) $(LIBS) -o $(TEST_TARGET)
	./$(TEST_TARGET)
	$(MAKE) clean

unit_test_dev:
	ls $(SRCDIR)/*.{h,c} $(TESTDIR)/*.{h,c} | entr -s 'make -s unit_test'

valgrind: $(STATIC_TARGET)
	$(CC) $(CFLAGS) $(TESTS) $(TEST_DEPS) $< $(LIBS) -o $(TEST_TARGET)
	$(VALGRIND) --leak-check=full --track-origins=yes -s ./$(TEST_TARGET)
	@$(MAKE) clean

fmt:
	@$(FMT) -i $(wildcard $(SRCDIR)/*) $(wildcard $(TESTDIR)/*) $(wildcard $(INCDIR)/*) $(wildcard $(EXAMPLEDIR)/*)
