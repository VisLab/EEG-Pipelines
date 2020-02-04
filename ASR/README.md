# ASR Standard pipeline

The Artifact Subspace Reconstruction Algorithm (ASR) uses
principal-component-like subspace decomposition to eliminate large transients. 
ASR essentially has two parameters:  
 * the interval used for calibration 
 * burst cutoff threshold   
In this implementation we assume the default calibration interval, which
is the first 5 minutes of the recording.  In the example we set the 
`burstCriterion` parameter to 5.