CXXFLAGS=-std=c++0x -g -Wall
SRCS = debug_if.cpp breakpoints.cpp rsp.cpp cache.cpp bridge.cpp memmap.cpp

CXX=g++
ifdef pulpemu
	CXXFLAGS+=-DFPGA -DPULPEMU
	CXX=arm-linux-gnueabihf-g++
	SRCS += mem_zynq_apb_spi.cpp
else ifdef pulpino
	ifeq ($(VIVADO_VERSION),2015.1)
		CXX=arm-xilinx-linux-gnueabi-g++
	else
		CXX=arm-linux-gnueabihf-g++
	endif
	CXXFLAGS+=-DFPGA
	SRCS += mem_zynq_spi.cpp
else
	CXX=g++
	SRCS += sim.cpp
endif

EXE_SRCS = main.cpp $(SRCS)
LIB_SRCS = $(SRCS)

ifdef GEN_LIB
all: debug_bridge libdebugbridge.so
else
all: debug_bridge
endif

clean:
	rm -f ./*.o
	rm -f ./debug_bridge
	rm -f ./libdebugbridge.so

debug_bridge: $(EXE_SRCS)
	$(CXX) $(CXXFLAGS) -o $@ $^

libdebugbridge.so: $(LIB_SRCS)
	$(CXX) $(CXXFLAGS) -g -O3 -fPIC -shared -o $@ $^

ifdef pulpino
push: debug_bridge
	scp ./debug_bridge root@$(FPGA_HOSTNAME):/root/
endif

sdk:
	make clean all GEN_LIB=1
	mkdir -p $(PULP_SDK_HOME)/install/ws/lib
	mkdir -p $(PULP_SDK_HOME)/install/ws/include
	cp *.h $(PULP_SDK_HOME)/install/ws/include
	cp debug_bridge $(PULP_SDK_HOME)/install/ws/bin
	cp libdebugbridge.so $(PULP_SDK_HOME)/install/ws/lib
