# Apply processing on the corpus files

You completed a basic tutorial and want to run the experiment using processing on the corpus
files before you extract features.

The preprocessing is done in the same way as the feature extraction:
In fade.d/processing.d there exist a folder for each possible preprocessing step.
Inside of each folder is a shell-script 'batch-process', which you need to adjust to suit your needs.
Your processing steps need to be able to read one wav-file in and write to a specified wav-file.

The processing step will read in the mixed wav-file inside of "corpus" and will write the processed files to
the "processing" directory.
## How to configure and run processing
After you have created the corpus in fade, enter the following to configure your processing step:
> fade-config <yourproject> processing <NameofprocessingFolder>

This will create the directory <yourproject>/config/processing, inside of which will be the sourcelist, the targetlist
and a directory 'scripts' containing the scripts for your processing step. Check again, if the configuration is correct,
or if it needs to be adjusted, and then run the processing step using:

> fade-config <yourproject> processing

This will run the processing steps and put the processed .wav-files in the subdirectory '<yourproject>/processed'.

## Finishing the project
Complete the project using the default steps starting from features-step from the basic tutorial.
(The feature stage will recognize, that you have processed files and will use them instead of the corpus-files.)

Alternatively, have a look at the ADVANCED_COMPLETE-SCRIPTS.md tutorial.


