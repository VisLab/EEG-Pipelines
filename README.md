# EEG-Pipelines
*Various automated MATLAB pipelines for processing EEG*

This repository holds several pipelines which were used to benchmark how
much differences in EEG preprocessing affect downstream results as reported
the following paper. This repository provides code that implements these 
pipelines. The original pipelines were implemented using a code infrastructure
that supports large-scale processing. The codes in this repository were 
stripped out of that infrastructure and redesigned to run on a single EEG
file in .set file format.

How to cite:
> How sensitive are EEG results to preprocessing methods: A Benchmarking study  
> Kay A. Robbins, Jonathan Touryan, Tim Mullen, Christian Kothe, Nima Bigdely-Shamlo  
> bioRxiv 2020.01.20.913327; doi: https://doi.org/10.1101/2020.01.20.913327 


## Setup
Before running any of these pipelines, you must make sure that you have

### Setup of EEGLAB
The instructions are based on EEGLAB v2019.1 or later. The following
EEGLAB plugins were installed in the default configuration:
 1. clean_rawdata2.1
 2. dipfit
 3. firfilt2.3
 4. ICLabel1.1

We also installed the following EEGLAB plugins:
 1. blinker1.1.2
 2. MARA1.2
 3. PrepPipeline0.55.3

By installation, we mean that these plugins are in the EEGLAB/plugin directory.
You should add them to your MATLAB path by running eeglab, not by trying to 
add individual directories to your path.

### Additional setup
You will also need go download eye-catch from https://github.com/bigdelys/eye-catch.
Add this directory to your path as well.

### Add the pipelines to your path by executing:
    runAddProjectPaths

## Data preparation

**Channel locations:** The input `EEG.set` file MUST have channel locations included. Furthermore, the 
`EEG.chanlocs.type` fields must be set so that the EEG channels have the
type 'EEG'. PREP, Blinker, MARA and other tools
rely on being able to reliably distinguish the EEG channels from auxilliary
channels in order to set their defaults. In our implementation, we remove 
the non-EEG channels in the first step.  If you do not wish to do this, you 
must give channels to be excluded in several steps. To simplify the 
implementation, this code removes non-EEG channels as the first step in the 
pipeline. 

**Reduction of number of channels:** The pipeline implementation reported
in our publication reduces the number of channels to 64 prior to performing
most of the pipeline. To do this, you must provide a channel mapping. We have
provided one channel mapping (
only EEG channels remain in the .set file before processing begins.

