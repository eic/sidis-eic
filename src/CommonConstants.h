// common constants for analysis
#ifndef CommonConstants_
#define CommonConstants_

namespace constants {

  // PDG codes
  enum pdg_enum {
    pdgElectron = 11,
    pdgProton   = 2212
  };

  // status codes
  enum status_enum {
    statusFinal = 1,
    statusBeam  = 4
  };

};

#endif