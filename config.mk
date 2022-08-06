# compiler and flags
CXX = g++
FLAGS = -g -Wno-deprecated -fPIC -fno-inline -Wno-write-strings
FLAGS += -fmax-errors=3
# extra flags
#FLAGS += -O0

# extra flags for Mac OS
UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
    FLAGS += -std=c++11
endif

# ROOT
DEPS = -I$(shell root-config --incdir)
LIBS = $(shell root-config --glibs)
#LIBS += -lMinuit -lRooFitCore -lRooFit -lRooStats -lProof -lMathMore

# DELPHES
DEPS += -I${DELPHES_HOME} -I${DELPHES_HOME}/external
LIBS += -L${DELPHES_HOME} -lDelphes

# MSTWPDF
DEPS += -I${MSTWPDF_HOME}
LIBS += -L${MSTWPDF_HOME} -lmstwpdf

# Fastjet Centauro
INCCENTAURO = 0
ifeq ($(INCCENTAURO),1)
LIBS+= -L${DELPHES_HOME}/external/fastjet/plugins/Centauro -lCentauro
DEPS+= -I${DELPHES_HOME}/external/fastjet/plugins/Centauro
endif
FLAGS += -DINCCENTAURO=$(INCCENTAURO)

# sidis-eic target
SIDIS_EIC = Sidis-eic
SIDIS_EIC_OBJ := lib$(SIDIS_EIC).so
