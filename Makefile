OPT = -O3
override CFLAGS += -g -Wall -Wwrite-strings -pedantic -funroll-loops -Wstrict-prototypes -Iscs -Iscs/include -Iscs/linsys $(OPT)

LINSYS = scs/linsys
DIRSRC = $(LINSYS)/cpu/direct
INDIRSRC = $(LINSYS)/cpu/indirect

EXTSRC = $(LINSYS)/external

OUT = dist

SCS_OBJECTS = scs/src/util.o scs/src/cones.o scs/src/exp_cone.o scs/src/aa.o scs/src/rw.o scs/src/linalg.o scs/src/ctrlc.o scs/src/scs_version.o scs/src/normalize.o
SCS_O = scs/src/scs.o
SCS_INDIR_O = scs/src/scs_indir.o

SRC_FILES = $(wildcard scs/src/*.c)
INC_FILES = $(wildcard scs/include/*.h)

AMD_SOURCE = $(wildcard $(EXTSRC)/amd/*.c)
LDL_SOURCE = $(wildcard $(EXTSRC)/qdldl/qdldl.c)
AMD_OBJS = $(AMD_SOURCE:.c=.o)
LDL_OBJS = $(LDL_SOURCE:.c=.o)

# Add wasm targets
WASM_TARGETS = $(OUT)/scs.wasm $(OUT)/scs.js

WASM_SRC = scs/src/scs.c scs/src/util.c scs/src/cones.c scs/src/exp_cone.c scs/src/aa.c scs/src/rw.c \
           scs/src/linalg.c scs/src/ctrlc.c scs/src/scs_version.c scs/src/normalize.c \
           $(DIRSRC)/private.c $(AMD_OBJS) $(LDL_OBJS) $(LINSYS)/scs_matrix.c $(LINSYS)/csparse.c

WASM_SRC += bindings/embind/scs_bindings.cpp

.PHONY: wasm
wasm: CC = emcc
wasm: $(WASM_TARGETS)

EMCC_OPTS = -s WASM=1 \
			--bind \
			-g0 \
			-Os \
			-s ALLOW_MEMORY_GROWTH=1 \
			-s MODULARIZE \
			-s 'EXPORT_NAME="createSCS"'

$(OUT)/scs.wasm $(OUT)/scs.js $(OUT)/scs.mjs: $(WASM_SRC)
	mkdir -p $(OUT)
	emcc $(CFLAGS) -o $(OUT)/scs.js $^ $(EMCC_OPTS) $(LDFLAGS)
	emcc $(CFLAGS) -o $(OUT)/scs.mjs $^ $(EMCC_OPTS) -s EXPORT_ES6=1 $(LDFLAGS)

.PHONY: clean purge
clean:
	@rm -rf $(TARGETS) $(SCS_O) $(SCS_INDIR_O) $(SCS_OBJECTS) $(AMD_OBJS) $(LDL_OBJS) $(LINSYS)/*.o $(DIRSRC)/*.o $(INDIRSRC)/*.o $(LINSYS)/gpu/*.o
	@rm -rf $(OUT)/*.dSYM
purge: clean
	@rm -rf $(OUT)
