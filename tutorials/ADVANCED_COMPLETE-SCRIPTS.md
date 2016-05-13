# Use the example scripts to complete partial projects

There are several examples of how fade can be used in scripts in the `fade/examples` directory.


## Complete a partial project or re-run a part of a project
One of them is dedicated to do complete a partial project:
> complete_project.sh

For example: you put your own feature files in place and want to perform the remaining steps (training, recognition, evaluation, figures) with the default settings without interruption.

The script `fade/examples/complete_project.sh` can be instructed to start at one of the following steps and then continue with the steps after:
- corpus
- features
- training
- recognition
- evaluation
- figures

In this example case you could just run:
> complete_project.sh <yourproject> training

Sometimes you finish a project but want to "correct" a parameter afterwards.
For example, you can edit the training parameters in `<yourproject>/config/training/parameters`.
Then you will want to re-run the steps starting with 'recognition':
> complete_project.sh <yourproject> recognition
This will overwrite the `recognition` subdirectory and the subdirectories of all following steps: `evaluation` `figures`


## Complete many partial projects
Another script is dedicated to completing several projects which share the same parent directory:
> complete_directory.sh

Lets say we want to run a matrix experiment with different types of features.
We set up several projects in the parent directory <projects>, e.g.:
- <projects>/matrix
- <projects>/matrix-logmelspec
- <projects>/matrix-mfcc
- <projects>/matrix-myfeatures

Now we want to complete the three projects that we configured the feature extraction for.
The script `fade/examples/complete_directory.sh` can then be used to complete all projects in a given directory, where the starting step must be the same.
> complete_directory.sh <projects> features

An optional filter pattern can be provided.
For example:
> complete_directory.sh <projects> features matrix-
This command will complete all projects in the <projects> directory that match the pattern 'matrix-' and in each project it will start with the feature extraxction step.



