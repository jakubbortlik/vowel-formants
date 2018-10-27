vowel-formants.praat
====================

This Praat script enables the user to inspect spectrograms, formants and pitch
of recordings when analysing vowel formants. It utilizes Praat's Demo window
(www.praat.org). It displays a portion of the spectrogram with highlighted vowel
boundaries, formants and pitch. The user can go back and forth from one items to
another, compare formant settings and Praat's analysis. The user can also listen
to individual recordings and mark them for later analysis. After the inspection,
the script calculates mean values of formants and writes the results to a table.

Requirements
------------

The script requires one or more sound files with textgrid annotations, placed
in directories with the names "sounds" and "textgrids", respectively.

The TextGrids
-------------

The TextGrids must have at least two interval tiers called "word" and "vowel".
The two tiers must have the same number of intervals. Non-empty intervals on the
word tier are extracted and spectrograms are drawn in the Demo window. The
intervals on the vowel tier are then highlighted, with margins within which the
measurements will be done. The margins should prevent formant transitions from
skewing the results, and they can be changed.

The annotation on the word tier can specify whether the word occurs phrase
initially or phrase finally. This is done by appending an "i" or "f" to the
word, e.g. "blacki" is the word "black" in phrase-initial position. If no such
"suffix" is used, it has to be specified in the initial Settings window,
otherwise the words in the annotation cannot be matched with those in the
stimuli list, see below.

Stimuli list
------------

The script can use a list of stimuli in the form of a simple csv file with three
columns: "vowel", "voicing", and "word", specifying, respectively, the target
vowel, voicing of the following consonant and the target word. This can be used
to check whether the annotation on the word and vowel tier does not contain
mistakes.

User control
------------

The interface can be controlled with the following keys:
- Q - quit
- P - previous item
- N - next item
- L - play the recording
- M - mark/unmark the item
- S - settings
