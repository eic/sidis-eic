# Largex-eic

General purpose analysis software for SIDIS at the EIC

This repository provides a set of common tools for the analysis of both full and
fast simulations, including the following features:

- kinematics reconstruction methods (e.g., leptonic, hadronic, Jacquet-Blondel,
  etc.)
- calculations of SIDIS variables, such as `PhiH` and `qT`, for single
  particles, as well as jet variables
- application of common set of cuts
- ability to specify arbitrary multi-dimensional binning schemes
- outputs include binned histograms, tables, and other data structures such as
  `TTrees`
- An analysis is primarily driven by macros, used to set up the binning and
  other settings

If you prefer to use your own analysis code, but would still like to make use of
the common tools provided in this repository (e.g., kinematics reconstruction),
this is also possible; you only need to stream the data structure you need, most
likely within the event loop. In this situation, it is recommended you fork the
repository (pull requests are also welcome).


# Setup and Dependencies

## Delphes

- the analysis is capable of reading `delphes` fast simulation output, and also
  provides a simple wrapper for `delphes` to help keep input `hepmc` and output
  `root` files organized
  - it is not required to use the `delphes` wrapper, but `delphes` libraries are
    needed for the analysis of fast simulation data
- first, make sure you have a build of `delphes` somewhere, preferably in a
  separate directory
- set environment variables before doing anything, so this repository knows where your
  `delphes` build is: `source env.sh /path/to/delphes/repository`
  - if you do not specify a path to `delphes` repository, it will use a default
    path given in `env.sh`; it is useful to edit this default path for your own
    convenience
  - it will also symlink `delphes` external code, so analysis macros
    will not complain

## Building

- build analysis code with `make` (environment variables must be set first, see above)
  - it requires a `root` build as well as `delphes`
  - all classes are found in the `src/` directory


# Simulation

## Delphes Fast Simulation

- for convenience, the wrapper script `exeDelphes.sh` is provided, which runs
  `delphes` on a given `hepmc` or `hepmc.gz` file, and sets the output file
  names and the appropriate configuration card
  - environment must be set first (`source env.sh`)
  - run `exeDelphes.sh` with no arguments for usage guide
  - in the script, you may need to change `exeDelphes` to the proper
    executable, e.g., `DelphesHepMC2` or `DelphesHepMC3`, depending
    on the format of your generator input
  - if reading a gunzipped file (`*.hepmc.gz`), this script will automatically
    stream it through `gunzip`, so there is no need to decompress beforehand
- the output will be a `TTree` stored in a `root` file
  - output files will be placed in `datarec/`
  - input `hepmc(.gz)` files can be kept in `datagen/`

## ATHENA Full Simulation

- TODO 



# Analysis Procedure

After simulation, this repository separates the analysis procedure into two
stages: (1) the *Analysis* stage includes the event loop, which processes either
fast or full simulation output, kinematics reconstruction, and your specified
binning scheme, while (2) the *Post-processing* stage includes histogram
drawing, comparisons, table printouts, and any feature you would like to add

The two stages are driven by macros. Example macros will eventually be added;
for now you can assume any macro named `analysis_*.C` or `postprocess_*.C` are
respective macros for the stages.

## Analysis

### Analysis Macro and Class

- the `Analysis` class is the main class that performs the analysis; it is 
  controlled at the macro level
  - a typical analysis macro must do the following:
    - instantiate `Analysis` (with file names, beam energies, crossing angle)
    - set up bin schemes and bins (arbitrary specification, see below)
    - set any other settings (e.g., a maximum number of events to process,
      useful for quick tests)
    - execute the analysis
    - see `src/Analysis.h` for further documentation in comments
  - the output will be a `root` file, filled with `TObjArray`s of
    histograms
    - each `TObjArray` can be for a different subset of events (bin), e.g.,
      different minimum `y` cuts, so that their histograms can be compared and
      divided; you can open the `root` file in a `TBrowser` to browse the
      histograms
    - the `Histos` class is a container for the histograms, and instances of
      `Histos` will also be streamed to `root` files, along with the binning
      scheme (handled by the `BinSet` class); downstream post processing code
      makes use of these streamed objects, rather than the `TObjArray`s

### Bin Specification

- The bins may be specified arbitrarily, using the `BinSet` and `CutDef` classes
  - see example `analysis_*C` macros
  - `CutDef` can store and apply an arbitrary cut for a single variable, such
    as:
    - ranges: `a<x<b` or `|x-a|<b`
    - minimum or maximum: `x>a` or `x<a`
    - no cut (useful for "full" bins)
  - The set of bins for a variable is defined by `BinSet`, a set of bins
    - These bins can be defined arbitrarily, with the help of the `CutDef`
      class; you can either:
      - Automatically define a set of bins, e.g., `N` bins between `a` and `b`
        - Equal width in linear scale
        - Equal width in log scale (useful for `x` and `Q2`)
        - Any custom `TAxis`
      - Manually define each bin
        - example: specific bins in `z` and `pT`:
          - `|z-0.3|<0.1` and `|pT-0.2|<0.05`
          - `|z-0.7|<0.1` and `|pT-0.5|<0.05`
        - example: 3 different `y` minima:
          - `y>0.05`
          - `y>0.03`
          - `y>0` (no cut)
          - note that the arbitrary specification permits bins to overlap, e.g.,
            an event with `y=0.1` will appear in all three bins
- Multi-dimensional binning
  - Binning in multi-dimensions is allowed, e.g., 3D binning in `x`,`Q2`,`z`
  - TODO: the current implementation is a prototype and there is a limit on the
    number of dimensions and the variables you are allowed to bin in are
    restricted (e.g., for tracks you are limited to `pT`,`x`,`z`,`Q`,`y`); an
    update to internal data structures aims to remove these restrictions
  - Be careful of the curse of dimensionality
    - You can restrict the binning in certain dimensions by taking only diagonal
      elements of a matrix of bins (see `diagonal` settings in `src/Analysis.h`)

### Simple Tree

- The `Analysis` class is capable of producing a simple `TTree`, handled by the
  `SimpleTree` class, which can also be useful for analysis
  - As the name suggests, it is a flat tree with a minimal set of variables,
    specifically needed for asymmetry analysis
  - The tree branches are configured to be compatible with 
    [asymmetry analysis code](https://github.com/c-dilks/dispin),
    built on the [BruFit](https://github.com/dglazier/brufit) framework
  - There is a switch in `Analysis` to enable/disable whether this tree is 
    written


# Post-Processing

### Post-Processing Macro and Class

- results processing is handled by the `PostProcessor` class, which does tasks
  such as printing tables of average values, and drawing ratios of histograms
  - this class is steered by `postprocess_*.C` macros, which includes the
    following:
    - instantiate `Analysis`, needed for bin loops and settings
    - instantiate `PostProcessor`, with the specified `root` file that contains
      output from the analysis macro
    - loop over bins and perform actions
- see `src/PostProcessor.h` and `src/PostProcessor.cxx` for available
  post-processing routines; you are welcome to add your own


# Contributions

- This repository is in an early stage of development, so bugs and issues are
  likely
- Contributions are welcome via pull requests and issues reporting; you may also
  find it useful to fork the repository for your own purposes, so that you do
  not have to feel limited by existing code (you can still send pull requests
  from a fork)
- It is recommended to keep up-to-date with developments by browsing the pull
  requests, issues, and viewing the latest commits by going to the `Insights`
  tab, and clicking `Netwok` to show the branch topology