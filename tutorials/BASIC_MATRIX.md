# Run a matrix sentence intelligibility prediction experiment

Create and enter a directory where you want to store your projects:
> mkdir projects
> cd projects

Check which version of fade you run and get a list of available actions:
> fade
The version is the digit triplet, e.g., "1.0.0".

Now you will create an empty fade project.
The fade version is stored to the project and it will be compatible only with this version of fade.
Let's choose *mat1* (mat for matrix) as the name of our project.
Okay, create the project and print some information about it:
> fade mat1
The information includes the version, a timestamp and the size of the projects.

Now let's set up the the corpus:
> fade mat1 corpus-matrix
This command copies a bunch of files which are specific to this type of corpus.
The configuration files are copied to the `config` subdirectory of the project.

There is no default speech/noise data.
You will need a copy of the OLSA sentences or similar speech material.
Each wav file is supposed to contain a sentence of 5 words.
For each word position (1 to 5) 10 alternatives are expected.
The sentences must be encoded in the filename with digits, e.g., 08231.wav.
The speech and noise files must be calibrated to 65dB SPL.
A sinewave with an RMS of 1 corresponds to 130dB SPL.
Copy the speech material to the subdirectory `source/speech/` and the noise file(s) to `source/noise/`.

Once you copied the speech and noise samples, generate the training and test stimuli:
> fade mat1 corpus-generate
Depending on the speed of your PC this can take a few minutes.

Look at the size of the project now:
> fade mat1
You can browse through the `corpus` subdirectory and listen to the generated signals.

Generate the training and test conditions:
> fade mat1 corpus-format
This command takes the list of all files in the corpus and generates training and test file lists.

Extract features from the signals:
> fade mat1 features
By default, this command uses only one thread and extracts separable Gabor filter bank (SGBFB) features.
The progress is indicated with dots.
Each dot represents a written feature file.
If you prefer Mel-frequency cepstral coefficient (MFCC) features try instead:
> fade tin1 features mfcc

Now we will train a Hidden Markov model (HMM) for each training condition:
> fade mat1 training
One thread is used and the progress is indicated with dots again.
The HMM definitions are plain text and can be accessed in the `training` subdirectory.

After training, we want to recognize the testing data using the trained HMMs.
> fade mat1 recognition
And again, one thread is used.
You can go to the `recognition` subdirectory and read the transcripts.
The folder names encode the training and the test conditions.

The transcriptions need to be evaluated:
> fade mat1 evaluation
They are compared to the corresponding labels.
A recognition rate in percent correct is calculated for each condition.
The summary file contains a line for each condition and indicates:
- the training condition
- the testing condition
- the total number of decisions
- the number of correct decisions

The evaluated results contain the sampled psychometric functions.
From these the detection thresholds can be determined and plotted:
> fade mat1 figures

Browse the `figures` subdirectory.
Besides .eps and .png grahpic files you will find a table containing the predicted SRTs for the different conditions.

