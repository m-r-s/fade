# Run an experiment using custom features

You completed a basic tutorial and want to run the experiment using your own features.

There are two different approaches to achieve this goal.
Which one you use depends on how your feature extraction code is implemented.
I recommend approach A, if possible.

## Approach A: Standalone Octave(Matlab) feature extraction function
You have an Octave-compatible function which takes the waveform and returns a feature matrix?
Perfect!

You can use the feature_extraction.m to hook up your code.
Therefore, instead of running the feature extracion, only configure it:
> fade-config <yourproject> features

Go to the `<yourproject>/config/features/matlab` directory.
Remove all files but the `feature_extraction.m` and copy your code into this directory.
Open the `feature_extraction.m` and adjust it to use your code.

The variable 'features' is supposed to contain a 2-dimensional matrix.
The first dimension is supposed to be the feature dimension and the second dimension to be time.
One feature vector every 10 ms is expected, i.e. the sample rate of the features is 100 samples/s.
The number of feature dimensions can be 1000 or even more.

Now, run the feature extraction:
> fade <yourproject> features


## Approach B: Process the signal files yourself
So, you dont have an Octave-compatible implementation?
No problem!

Instead of running the feature extracion only configure it:
> fade-config <yourproject> features

Go to the `<yourproject>/config/features` directory.
There are two filelists that belong together: `sourcelist` and `targetlist`.
Each line of `sourcelist` contains the full path to a waveform.
The corresponding line of `targetlist` contains the full path of the respective feature file.

You can these two lists to create the corresponding target directories and save your features in HTK format to the target files.

Alternatively, copy the `corpus` subdirectory, which contains the .wav files, to the `features` directory.
You can use the `cp` command:
> cp -r <yourproject>/corpus <yourproject>/features
Then, process all the .wav files in the `features` subdirectory and save the features to [filename(1:end-3) 'htk'] instead of wav.
Afterwards, delete all .wav files from the features directory:
> find <yourproject>/features -iname '*.wav' -delete


## Finishing the project
Complete the project using the default steps from the basic tutorial.

Alternatively, have a look at the ADVANCED_COMPLETE-SCRIPTS.md tutorial.


