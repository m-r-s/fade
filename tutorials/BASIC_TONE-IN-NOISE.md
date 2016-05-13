# Run a tone-in-noise detection experiment

Create and enter a directory where you want to store your projects:
> mkdir projects
> cd projects

Check which version of fade you run and get a list of available actions:
> fade
The version is the digit triplet, e.g., "1.0.0".

Now you will create an empty fade project.
The fade version is stored to the project and it will be compatible only with this version of fade.
Let's choose *tin1* (tin for tone-in-noise) as the name of our project.
Okay, create the project and print some information about it:
> fade tin1
The information includes the version, a timestamp and the size of the projects.

Now let's set up the the corpus:
> fade tin1 corpus-stimulus
This command copies a bunch of files which are specific to this type of corpus.
The configuration files are copied to the `config` subdirectory of the project.
The default experiment is a tone-in-noise detection experiment for different tone lengths.

Now, generate the training and test stimuli:
> fade tin1 corpus-generate
Depending on the speed of your PC this can take a few minutes.
The remaining time for the current generation process is indicated from time to time.

Look at the size of the project now:
> fade tin1
It should be about a Gigabyte by now.
You can browse through the `corpus` subdirectory and listen to the generated signals.

Generate the training and test conditions:
> fade tin1 corpus-format
This command takes the list of all files in the corpus and generates training and test file lists.

Extract features from the signals:
> fade tin1 features
By default, this command uses all available processors and extracts separable Gabor filter bank (SGBFB) features.
The progress is indicated with digits from 0 to 9.
Each digit represents a written feature file.
If you prefer Mel-frequency cepstral coefficient (MFCC) features try instead:
> fade tin1 features mfcc

Now we will train a Hidden Markov model (HMM) for each training condition:
> fade tin1 training
All available processors are used and the progress is indicated with digits again.
The HMM definitions are plain text and can be accessed in the `training` subdirectory.

After training, we want to recognize the testing data using the trained HMMs.
> fade tin1 recognition
And again all available processors are used.
You can go to the `recognition` subdirectory and read the transcripts.
The folder names encode the training and the test conditions.

The transcriptions need to be evaluated:
> fade tin1 evaluation
They are compared to the corresponding labels.
A recognition rate in percent correct is calculated for each condition.
The summary file contains a line for each condition and indicates:
- the training condition
- the testing condition
- the total number of decisions
- the number of correct decisions

The evaluated results contain the sampled psychometric functions.
From these the detection thresholds can be determined and plotted:
> fade tin1 figures

Browse the `figures` subdirectory.
Besides .eps and .png grahpic files you will find a table containing the thresholds for the different conditions.

