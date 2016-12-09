#===============================================================================
#
#          File:  vowel_formants.praat
# 
#   Description:  measure F0, F1-FN and duration from labelled words
#
#        Author:  Jakub Bortlík, <jakub.bortlik@gmail.com>
#  Organization:  
#       Created:  2016-05-27
#      Revision:  2016-08-07
#       Version:  Vowel-Formant Inspection Tool v0.1
#       License:  Copyright (c) 2016, Jakub Bortlík
#                 This program is free software: you can redistribute it and/or
#                 modify it under the terms of the GNU General Public License as
#                 published by the Free Software Foundation, either version 3 of
#                 the License, or (at your option) any later version.
#                 
#                 This program is distributed in the hope that it will be
#                 useful, but WITHOUT ANY WARRANTY; without even the implied
#                 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#                 PURPOSE. See the GNU General Public License for more details.
#                 
#                 You should have received a copy of the GNU General Public
#                 License along with this program. If not, see
#                 <http://www.gnu.org/licenses/>.
#
#===============================================================================

#-------------------------------------------------------------------------------
# Constants
#-------------------------------------------------------------------------------
textgrids_dir$ = "textgrids/"		; the directory with the textgrids
sounds_dir$ = "sounds/"				; the directory with the textgrids
results_dir$ = "results/"			; the directory to save result tables in
stimuli$ = "stimuli.csv"			; the list of stimuli with vowels and voicing
default_margin = 30					; margin (in %) of the V in which F are not measured 
remember_margin = 1					; remeber the margin for the next word
remembered_margin = default_margin
margin = 30							; use this variable in case the settings window is canceled
;apply_to_all = 0					; apply the margin settings to all extracts of the current speaker
tier1$ = "word"						; 1st tier name
tier2$ = "vowel"					; 2nd tier name
tier3$ = "formants"					; 3rd tier name
require_tiers = 2					; number of tiers in the annotation
suffix_length = 1					; the number of characters in the "position suffix" of the words
max_n_formants = 5					; the maximum number of formants in the analysis
n_formants = 3						; the number of formants to be measured
left_female_pitch = 100				; the floor for pitch measurements in female voices
right_female_pitch = 600			; the ceiling for pitch measurements in female voices
left_male_pitch = 75				; the floor for pitch measurements in male voices
right_male_pitch = 300				; the ceiling for pitch measurements in male voices
female_frequency = 5700				; the maximum frequency of the formant in Hz for female speakers
male_frequency = 5300				; the maximum frequency of the formant in Hz for male speakers
decimals = 3						; number of decimal spaces in values
stimuli_list = 0

#-------------------------------------------------------------------------------
# Constants for the Demo window
#-------------------------------------------------------------------------------
x_min_s = 10						; left border of spectrogram figure
x_max_s = 93						; right border of spectrogram figure
y_min_s = 20						; bottom vertical border of spectrogram figure
y_max_s = 85						; top vertical border of spectrogram figure
y_t = 8								; vertical position of the button texts
y_t_offset = 3						; vertical offset of button borders
button1_x1 = 4
button1_x2 = 11
button1_t = (button1_x1 + button1_x2) / 2
button1$ = "#%Quit"
button2_x1 = 14
button2_x2 = 26
button2_t = (button2_x1 + button2_x2) / 2
button2$ = "#%Previous"
button3_x1 = 29
button3_x2 = 36
button3_t = (button3_x1 + button3_x2) / 2
button3$ = "#%Next"
button4_x1 = 39
button4_x2 = 47
button4_t = (button4_x1 + button4_x2) / 2
button4$ = "p#%Lay"
button5_x1 = 50
button5_x2 = 57
button5_t = (button5_x1 + button5_x2) / 2
button5$ = "%#Mark"
button6_x1 = 60
button6_x2 = 72
button6_t = (button6_x1 + button6_x2) / 2
button6$ = "%#Settings"
quit = 0							; if quit = 1 buttons are painted in grey

x_margin = 4				; the horizontal position of the margin description
x_m_rect1 = 4		; coordinates to paint over the old margin description
x_m_rect2 = 24	; coordinates to paint over the old margin description
y_margin = 14				; the vertical position of the margin description
y_m_rect1 = 12	; coordinates to paint over the old margin description
y_m_rect2 = 16	; coordinates to paint over the old margin description

#-------------------------------------------------------------------------------
# ask the user for some settings of the script
#-------------------------------------------------------------------------------
initial_settings = 1
@initial_settings
# @choose_settings

#-------------------------------------------------------------------------------
# generate the column names for the speaker tables
#-------------------------------------------------------------------------------
f_list$ = "F0"
for f to n_formants 						; add columns for formants
	f_list$ = f_list$ + " F" + string$ (f)
endfor
if n_formants > 1
	for f from 2 to n_formants 				; add columns for formant ratios
		lower_f = f - 1
		f_list$ = f_list$ + " F" + string$ (f) + "/F" + string$ (lower_f)
	endfor
endif
speaker_column_names$ = "speaker word vowel 'f_list$' duration proportion"
if suffix_length > 0
	speaker_column_names$ = speaker_column_names$ + " position"
endif
if get_voicing = 1
	speaker_column_names$ = speaker_column_names$ + " voicing"
endif
speaker_column_names$ = speaker_column_names$ + " marked"

#-------------------------------------------------------------------------------
# generate the column names for the final table
#-------------------------------------------------------------------------------
final_column_names$ = "speaker 'f_list$' duration"

#-------------------------------------------------------------------------------
# prepare the demo window
#-------------------------------------------------------------------------------
demoWindowTitle: "Check the formants"
demo Erase all
demo Solid line
demo Black

#-------------------------------------------------------------------------------
# make a list of textgrids
#-------------------------------------------------------------------------------
list_textgrids = Create Strings as file list: "textgrids", textgrids_dir$ +
... "*.TextGrid"
n_textgirds = Get number of strings
if n_textgirds = 0
	exitScript: "There are no TextGrids in the directory 'textgrids_dir$'"
endif

#-------------------------------------------------------------------------------
# check whether all files exist and are readable
#-------------------------------------------------------------------------------
@check_files

#-------------------------------------------------------------------------------
# read in the list of stimuli
#-------------------------------------------------------------------------------
stimuli_readable = fileReadable (stimuli$)
if stimuli_list = 1
	if !stimuli_readable
		exitScript: "The file ", stimuli$, " does not exist or is not readable!"
	else
		stimuli = Read from file: stimuli$
	endif
else
	stimuli = 0
	get_voicing = 0
endif

#-------------------------------------------------------------------------------
# create the final results table
#-------------------------------------------------------------------------------
final_results = Create Table with column names: "FINAL_RESULTS", n_textgirds,
... final_column_names$

#-------------------------------------------------------------------------------
# process one speaker at a time
#-------------------------------------------------------------------------------
for i to n_textgirds
	#---------------------------------------------------------------------------
	# get the textgrid name and load the textgrid and sound
	#---------------------------------------------------------------------------
	selectObject: list_textgrids
	textgrid_name$ = Get string: i						; name of the textgrid
	textgrid = Read from file: textgrids_dir$ + textgrid_name$
	textgrid'i' = textgrid
	sound = Read from file: sounds_dir$ + sound_name'i'$
	sound'i' = sound

	#---------------------------------------------------------------------------
	# get the speaker name, replace underscores with Praat backslash trigraphs
	# for the demo Window
	#---------------------------------------------------------------------------
	speaker$ = textgrid_name$ - ".TextGrid"				; code of the speaker
	if index (speaker$, "_") > 0
		demo_speaker'i'$ = replace$ (speaker$, "_", "\_ ", 0)
	endif
	#---------------------------------------------------------------------------
	# assign values depending on the gender of the speaker
	#---------------------------------------------------------------------------
	@gender

	#---------------------------------------------------------------------------
	# check the integrity of the textgrid
	#---------------------------------------------------------------------------
	@check_textgrid

	#---------------------------------------------------------------------------
	# extract sounds of individual words
	#---------------------------------------------------------------------------
	@extract_words

	#---------------------------------------------------------------------------
	# create the results table for the speaker
	#---------------------------------------------------------------------------
	results'i' = Create Table with column names: "RESULTS_" + speaker$, n_words,
	... speaker_column_names$

	for s to n_words
		#-----------------------------------------------------------------------
		# assign the default "margin" value to individual words if it does not
		# exist yet
		#-----------------------------------------------------------------------
		if !variableExists ("margin'i'_'s'")
			margin'i'_'s' = default_margin
		endif
		#-----------------------------------------------------------------------
		# get the word boundaries from the textgrid
		#-----------------------------------------------------------------------
		@word_boundaries
		#-----------------------------------------------------------------------
		# get the vowel boundaries from the textgrid
		#-----------------------------------------------------------------------
		@vowel_boundaries
		#-----------------------------------------------------------------------
		# get the boundaries of the section where formants will be measured
		#-----------------------------------------------------------------------
		@formant_boundaries
		#-----------------------------------------------------------------------
		# create spectrograms, formants and pitches from extracts
		#-----------------------------------------------------------------------
		if not variableExists ("spectrogram'i'_'s'")
			@to_spectrogram
		endif
		if not variableExists ("formant'i'_'s'")
			@to_formant
		endif
		if not variableExists ("pitch'i'_'s'")
			@to_pitch
		endif
		#-----------------------------------------------------------------------
		# draw spectrogram, formants and pitch, and ask for user evaluation
		#-----------------------------------------------------------------------
		@draw_word

		@write_results
		#-----------------------------------------------------------------------
		# wait for user input between individual words
		#-----------------------------------------------------------------------
		next_word = 0
		while !next_word and demoWaitForInput()
			#-------------------------------------------------------------------
			# continue to the next word
			#-------------------------------------------------------------------
			if demoKey$ () = "n"
				next_word = 1
			#-------------------------------------------------------------------
			# go back to the previous word
			#-------------------------------------------------------------------
			elif demoKey$ () = "p" and s > 1
				next_word = -1
			#-------------------------------------------------------------------
			# quit
			#-------------------------------------------------------------------
			elif demoKey$ () = "q"
				quit = 1
				@draw_buttons
				exitScript: "Exited on demand."
			#-------------------------------------------------------------------
			# mark word for later inspection
			#-------------------------------------------------------------------
			elif demoKey$ () = "m"
				if marked'i'_'s' = 0
					marked'i'_'s' = 1				; mark word extract'i'_'s'$
					@draw_marked
					selectObject: textgrid
					extract_textgrid'i'_'s' = Extract part: w_start's', w_end's', "yes"
					Rename: new_extract_name'i'_'s'$
					Insert interval tier: 3, tier3$
					Insert boundary: 3, f_start's'
					Insert boundary: 3, f_end's'
					Set interval text: 3, 2, textgrid_percent'i'_'s'$
				elif marked'i'_'s' = 1
					marked'i'_'s' = 0
					removeObject: extract_textgrid'i'_'s'
					@draw_word
				endif
				@write_results
			#-------------------------------------------------------------------
			# choose the settings and redraw the screen if some settings have
			# been changed
			#-------------------------------------------------------------------
			elif demoKey$ () = "s"
				@choose_settings
				@gender
				if clicked = 2
					margin'i'_'s' = margin
				endif
				#---------------------------------------------------------------
				# redraw screen if Margins have been changed
				#---------------------------------------------------------------
				if old_margin <> margin'i'_'s'
					@draw_spectrogram
					@formant_boundaries
					@draw_formant_lines
				endif
				#---------------------------------------------------------------
				# redraw text if devault margin has been changed
				#---------------------------------------------------------------
				if old_default_margin <> default_margin
					@write_default_margin
				endif
				#---------------------------------------------------------------
				# redraw screen if max frequency settings are changed
				#---------------------------------------------------------------
				if (gender = 2 and old_female_frequency <> female_frequency) or
				... (gender = 1 and old_male_frequency <> male_frequency)
					if variableExists ("spectrogram'i'_'s'")
						removeObject: spectrogram'i'_'s'
					endif
					@to_spectrogram
					if variableExists ("formant'i'_'s'")
						removeObject: formant'i'_'s'
					endif
					@to_formant
					@draw_spectrogram
					@draw_formant_lines
				endif
				#---------------------------------------------------------------
				# redraw screen if pitch settings are changed
				#---------------------------------------------------------------
				if (gender = 1 and (old_left_male_pitch <> left_male_pitch or
				... old_right_male_pitch <> right_male_pitch)) or
				... (gender = 2 and (old_left_female_pitch <> left_female_pitch
				... or old_right_female_pitch <> right_female_pitch))
					if variableExists ("pitch'i'_'s'")
						removeObject: pitch'i'_'s'
					endif
					@to_pitch
					@draw_spectrogram
					@draw_formant_lines
				endif
				@write_results
			#-------------------------------------------------------------------
			# play the sound by pressing "l"
			#-------------------------------------------------------------------
			elif demoKey$ () = "l"
				@play_extract
			endif
		endwhile
		#-----------------------------------------------------------------------
		# if "p" for previous word was pressed:
		#-----------------------------------------------------------------------
		if next_word = -1
			s -= 2
		endif
	endfor

	#---------------------------------------------------------------------------
	# calculate and write the mean values for Formants and other measurements
	#---------------------------------------------------------------------------
	@write_means

	#---------------------------------------------------------------------------
	# draw the screen after individual speakers
	#---------------------------------------------------------------------------
	demo Black
	demo Erase all
	demo Select inner viewport: 0, 100,  0, 100
	demo Axes: 0, 100, 0, 100
	demo Text special: 50, "centre", 50, "half", "Helvetica", 40, "0", "Speaker
	... " + demo_speaker'i'$ + " done."
	pause = 1
	@draw_buttons

	#---------------------------------------------------------------------------
	# wait for user input between individual speakers
	#---------------------------------------------------------------------------
	next_speaker = 0
	while i < n_textgirds and !next_speaker and demoWaitForInput()
		if demoKey$ () = "n"
			next_speaker = 1
		elif demoKey$ () = "q"
			quit = 1
			@draw_buttons
			exitScript: "Exited on demand."
		endif
	endwhile
	pause = 0
	#-------------------------------------------------------------------
	# remove objects that are not needed anymore
	#-------------------------------------------------------------------
	removeObject: sound'i'
	removeObject: textgrid'i'
	for s to n_words
		removeObject: spectrogram'i'_'s'
		removeObject: formant'i'_'s'
		removeObject: pitch'i'_'s'
		if marked'i'_'s' = 0
			removeObject: extract'i'_'s'
		endif
	endfor
endfor

#-------------------------------------------------------------------------------
# final screen
#-------------------------------------------------------------------------------
demo Black
demo Erase all
demo Select inner viewport: 0, 100,  0, 100
demo Axes: 0, 100, 0, 100
demo Text special: 50, "centre", 85, "half", "Helvetica", 40, "0", "Finished"
demo Text special: 10, "left", 75, "half", "Helvetica", 20, "0", "Saved results
... in folder " + results_dir$
for i to n_textgirds
	demo Text special: 10, "left", 74 - (i * 4), "half", "Helvetica", 15, "0",
	... demo_speaker'i'$ + ".csv"
endfor
@remove_initial_files

#===  PROCEDURE  ===============================================================
#         NAME: check_files
#  DESCRIPTION: check whether the textgrids and the corresponding sound files
#               are readable
#  PARAMETER 1: ---
#===============================================================================
procedure check_files
	for i to n_textgirds
		selectObject: list_textgrids
		#-----------------------------------------------------------------------
		# check the TextGrid file
		#-----------------------------------------------------------------------
		textgrid_name$ = Get string: i				; name of the textgrid
		textgrid_exists = fileReadable (textgrids_dir$ + textgrid_name$)
		if !textgrid_exists
			exitScript: "Textgrid file ", textgrid_name$, " does not exist or is
			... not readable!"
		endif
		#-----------------------------------------------------------------------
		# check the long sound file
		#-----------------------------------------------------------------------
		sound_name$ = textgrid_name$ - "TextGrid" + "wav"	; name of the sound
		sound_name'i'$ = sound_name$
		sound_exists = fileReadable (sounds_dir$ + sound_name$)
		if !sound_exists
			exitScript: "Sound file ", sound_name$, " does not exist or is not
			... readable!"
		endif
	endfor
endproc    # ----------  end of procedure check_files  ----------

#===  PROCEDURE  ===============================================================
#         NAME: check_textgrid
#  DESCRIPTION: - check whether the tier names are correct
#               - check whether the number of intervals is the same on the
#               "word" and "vowel" tiers
#               - get the labels on the "word" and "vowel" tiers
#  PARAMETER 1: ---
#===============================================================================
procedure check_textgrid
	textgrid_ok = 0
	while !textgrid_ok
		textgrid_ok = 1
		#-----------------------------------------------------------------------
		# check whether the duration of the sound and of the textgrid differ
		#-----------------------------------------------------------------------
		selectObject: sound
		sound_duration = Get total duration
		selectObject: textgrid
		textgrid_duration = Get total duration
		if textgrid_duration <> sound_duration
			beginPause: "Mistake in annotation"
				comment: "The duration of the textgrid 'textgrid_name$' and
				... of the"
				comment: "corresponding sound differ!"
			clicked = endPause: "Scale times", "OK", 1
			if clicked = 1
				selectObject: textgrid
				plusObject: sound
				Scale times
			endif
		endif

		#-----------------------------------------------------------------------
		# check whether the tier names are correct
		#-----------------------------------------------------------------------
		selectObject: textgrid
		has_tiers = Get number of tiers
		for h to has_tiers
			has_tier'h'$ = Get tier name: h
		endfor
		tiers_ok = 1
		for .r to require_tiers
			tier_present = 0
			require_tier$ = tier'.r'$
			for h to has_tiers
				if require_tier$ = has_tier'h'$ 
					tier_present += 1
					'require_tier$'_tier = h
				endif
			endfor
			if tier_present = 0
				tiers_ok = 0
				textgrid_ok = 0
				beginPause: "Mistake in annotation"
					comment: "The tier ""'require_tier$'"" is missing!"
				clicked = endPause: "OK", 1
			elif tier_present > 1
				tiers_ok = 0
				textgrid_ok = 0
				beginPause: "Mistake in annotation"
					comment: "There are 'tier_present' tiers with the same
					... name!"
				clicked = endPause: "OK", 1
			endif
		endfor

		if tiers_ok = 1
			#-------------------------------------------------------------------
			# check whether the number of intervals is the same on the "word"
			# and "vowel" tiers
			#-------------------------------------------------------------------
			selectObject: textgrid
			n_word_intervals = Get number of intervals: word_tier
			n_vowel_intervals = Get number of intervals: vowel_tier
			if n_word_intervals <> n_vowel_intervals
				textgrid_ok = 0
				beginPause: "Mistake in annotation"
					comment: "The number of intervals on tiers 1 and 2 in file
					... ""'textgrid$'"" differs."
				clicked = endPause: "OK", 1
			endif

			#-------------------------------------------------------------------
			# check whether there are any spaces in the annotation and whether
			# the number of labels on the word tier matches the number of labels
			# on the vowel tier
			#-------------------------------------------------------------------
			n_words = 0
			for n to n_word_intervals
				selectObject: textgrid
				word$ = Get label of interval: word_tier, n
				if word$ = " " or word$ = "  "
					textgrid_ok = 0
					beginPause: "Mistake in annotation"
						comment: "There is a space on tier 'word_tier' in
						... interval 'n' in textgrid 'textgrid_name$'."
					clicked = endPause: "OK", 1
				elif word$ <> ""
					n_words += 1
				endif
			endfor
			n_vowels = 0
			for n to n_vowel_intervals
				selectObject: textgrid
				vowel$ = Get label of interval: vowel_tier, n
				if vowel$ = " " or vowel$ = "  "
					textgrid_ok = 0
					beginPause: "Mistake in annotation"
						comment: "There is a space on tier 'vowel_tier' in
						... interval 'n' in textgrid 'textgrid_name$'."
					clicked = endPause: "OK", 1
				elif vowel$ <> ""
					n_vowels += 1
				endif
			endfor
			if n_words > n_vowels
				textgrid_ok = 0
				extra_labels = n_words - n_vowels
					beginPause: "Mistake in annotation"
						comment:  "There are 'extra_labels' more labels on the
						... ""word"" tier than on the ""vowel"" tier in"
						comment: "textgrid 'textgrid_name$'."
					clicked = endPause: "OK", 1
			elif n_words < n_vowels
				textgrid_ok = 0
				extra_labels = n_vowels - n_words
					beginPause: "Mistake in annotation"
						comment:  "WRONG: There are 'extra_labels' more labels
						... on the ""vowel"" tier than on the ""word"" tier in"
						comment: "textgrid 'textgrid_name$'."
					clicked = endPause: "OK", 1
			else
				extra_labels = 0
			endif

			#-----------------------------------------------------------------------
			# assign values to the word'X'$ variables and check whether the
			# words are on the stimuli list
			#-----------------------------------------------------------------------
			n_words = 0
			for n to n_word_intervals
				selectObject: textgrid
				word$ = Get label of interval: word_tier, n
				if word$ <> ""
					n_words += 1
					word_full'n_words'$ = word$
					full_length = length (word$)
					if suffix_length > 0
						word'n_words'$ = left$ (word$, full_length - suffix_length)
						#---------------------------------------------------------------
						# get the position from the suffix
						#---------------------------------------------------------------
						position'n_words'$ = right$ (word$, suffix_length)
					else
						word'n_words'$ = word$
					endif

					#---------------------------------------------------------------
					# check if the word is on the list of stimuli
					#---------------------------------------------------------------
					stimulus_vowel'n_words'$ = ""
					if stimuli_list = 1
						selectObject: stimuli
						stimulus = Search column: "word", word'n_words'$
						if stimulus = 0
							textgrid_ok = 0
							wrong_word$ = word_full'n_words'$
							selectObject: textgrid
							beginPause: "Mistake in annotation"
								comment: "The word ""'wrong_word$'"" is not in the
								... stimuli list! The ""position suffix"" may be"
								comment: "wrong or there is a space in the
								... annotation!"
							clicked = endPause: "OK", 1
						else
							#---------------------------------------------------
							# get the target V and the voicing of the consonant
							# after it from the stimuli list
							#---------------------------------------------------
							stimulus_vowel'n_words'$ = Get value: stimulus, "vowel"
							if get_voicing = 1
								voicing'n_words'$ = Get value: stimulus, "voicing"
							endif
						endif
					endif
				endif
			endfor
			n_words'i' = n_words

			#-------------------------------------------------------------------
			# assign values to the vowel'X'$ variables
			#-------------------------------------------------------------------
			n_vowels = 0
			for n to n_vowel_intervals
				selectObject: textgrid
				vowel$ = Get label of interval: vowel_tier, n
				if vowel$ <> ""
					n_vowels += 1
					vowel'n_vowels'$ = vowel$
					#-----------------------------------------------------------
					# if the stimuli list exists, check whether the vowel in the
					# textgrid is the same in the list
					#-----------------------------------------------------------
					if (stimuli_list = 1) and variableExists
					... ("stimulus_vowel'n_vowels'$") and
					... (stimulus_vowel'n_vowels'$ <> "") and
					... (vowel$ <> stimulus_vowel'n_vowels'$)
						textgrid_ok = 0
						wrong_word$ = word_full'n_vowels'$
						beginPause: "Mistake in annotation"
							comment: "The vowel label for word ""'wrong_word$'""
							... is probably wrong: ""'vowel$'""."
						clicked = endPause: "OK", 1
					endif
				endif
			endfor
		endif
	endwhile
endproc    # ----------  end of procedure check_textgrid  ----------

#===  PROCEDURE  ===============================================================
#         NAME: extract_words
#  DESCRIPTION: extract portions of the sound from textgrid intervals which
#               have some text on the words tier
#  PARAMETER 1: ---
#===============================================================================
procedure extract_words
	selectObject: textgrid
	plusObject: sound
	Extract non-empty intervals: word_tier, "yes" ; yes stands for "keep times"
	for w to n_words
		extract'i'_'w' = selected ("Sound", w)
		extract'i'_'w'$ = selected$ ("Sound", w)
		marked'i'_'w' = 0							; words are unmarked by default
	endfor
	for w to n_words
		selectObject: extract'i'_'w'
		new_extract_name'i'_'w'$ = string$ (w) + "_" + extract'i'_'w'$ + "_" + speaker$
		Rename: new_extract_name'i'_'w'$
	endfor
endproc    # ----------  end of procedure extract_words  ----------

#===  PROCEDURE  ===============================================================
#         NAME: word_boundaries
#  DESCRIPTION: get the start + end time of the word
#  PARAMETER 1: ---
#===============================================================================
procedure word_boundaries
	selectObject: extract'i'_'s'
	w_start's' = Get start time
	w_end's' = Get end time
	word_duration's' = Get total duration
endproc    # ----------  end of procedure word_boundaries  ----------

#===  PROCEDURE  ===============================================================
#         NAME: vowel_boundaries
#  DESCRIPTION: find the starting/end points of vowels and the sections without
#               margins in which formants will be measured. Shift the times with
#               respect to the beginning of the word
#  PARAMETER 1: ---
#===============================================================================
procedure vowel_boundaries
	selectObject: textgrid
	orig_v_start = Get starting point: vowel_tier, (2 * s) ; vowel starting time
	orig_v_end = Get end point: vowel_tier, (2 * s)		; vowel end time
	v_start's' = orig_v_start
	v_end's' = orig_v_end
	v_duration's' = v_end's' - v_start's'					; vowel duration
endproc    # ----------  end of procedure vowel_boundaries  ----------

#===  PROCEDURE  ===============================================================
#         NAME: formant_boundaries
#  DESCRIPTION: Find the starting/end points the sections in which formants will
#               be measured.
#               the word
#  PARAMETER 1: ---
#===============================================================================
procedure formant_boundaries
	percent'i'_'s' = 100 - (2 * margin'i'_'s')		; proportion of the vowel in which formants are measured
	percent'i'_'s'$ = " (" + string$ (percent'i'_'s') + "\% )" ; the text which will be written in the Demo window
	textgrid_percent'i'_'s'$ = "(" + string$ (percent'i'_'s') + "%)" ; the text which will be written in the extract TextGrid

	f_start's' = v_start's' + (v_duration's' * margin'i'_'s' / 100)	; starting time + margin
	f_end's' = v_end's' - (v_duration's' * margin'i'_'s' / 100)		; end time - margin
	v_start_line's' = ((v_start's' - w_start's') * 100) / word_duration's'
	v_end_line's' = ((v_end's' - w_start's') * 100) / word_duration's'
	f_start_line's' = ((f_start's' - w_start's') * 100) / word_duration's'
	f_end_line's' = ((f_end's' - w_start's') * 100) / word_duration's'
	mid_line's' = (f_end_line's' + f_start_line's') / 2
endproc    # ----------  end of procedure formant_boundaries  ----------

#===  PROCEDURE  ===============================================================
#         NAME: draw_word
#  DESCRIPTION: draw the spectrogram and the formants in the Demo window and ask
#               for user input to correct the formant analysis settings
#  PARAMETER 1: ---
#===============================================================================
procedure draw_word
	#-----------------------------------------------------------------------
	# prepare the Demo window for drawing
	#-----------------------------------------------------------------------
	demo Erase all
	demo Select inner viewport: 0, 100,  0, 100
	demo Axes: 0, 100, 0, 100
	demo Black
	demo Text special: 50, "centre", 95, "half", "Helvetica", 20, "0",
	... demo_speaker'i'$ + ": " + word's'$ + " ('s'/'n_words')"
	pause = 0
	@draw_buttons
	@draw_spectrogram
	@draw_formant_lines
	@write_default_margin
endproc    # ----------  end of procedure draw_word  ----------

#===  PROCEDURE  ===============================================================
#         NAME: initial_settings
#  DESCRIPTION: ask the user for the initial settings
#  PARAMETER 1: ---
#===============================================================================
procedure initial_settings
	#---------------------------------------------------------------------------
	# record previous values of variables
	#---------------------------------------------------------------------------
	settings_ok = 0					; variable to check the settings values
	while !settings_ok
		beginPause: "Choose the settings"
			comment: "Choose the default initial and final margin: 1-49 %."
			positive: "Default margin", default_margin
#			if initial_settings = 0
#				comment: "Apply to all extracts of the current speaker?"
#				boolean: "Apply to all", apply_to_all
#			endif
			comment: "Choose the number of formants to measure"
			natural: "N formants", n_formants
			comment: "Choose the max frequency (Hz) for female speakers"
			natural: "Female frequency", female_frequency
			comment: "Choose the max frequency (Hz) for male speakers"
			natural: "Male frequency", male_frequency
			natural: "left female pitch", left_female_pitch
			natural: "right female pitch", right_female_pitch
			natural: "left male pitch", left_male_pitch
			natural: "right male pitch", right_male_pitch
			comment: "What is the length of the ""position suffix""? (Set to
			... ""0"" if there is none)"
			integer: "Suffix length", suffix_length
			comment: "Do you want to use a stimuli list?"
			boolean: "Stimuli list", 1
			comment: "Get voicing of preceding consonants in stimuli list?"
			boolean: "Get voicing", 1
			comment: "Choose the number of digits after the decimal point"
			natural: "Decimals", decimals
		clicked = endPause: "Cancel", "Continue", 2, 1
		@check_settings
	endwhile
	initial_settings = 0
endproc    # ----------  end of procedure initial_settings  ----------

#===  PROCEDURE  ===============================================================
#         NAME: choose_settings
#  DESCRIPTION: ask the user for settings during the main procedure
#  PARAMETER 1: ---
#===============================================================================
procedure choose_settings
	#---------------------------------------------------------------------------
	# record previous values of variables
	#---------------------------------------------------------------------------
	if variableExists ("margin'i'_'s'")
		old_margin = margin'i'_'s'
	else
		old_margin = default_margin
	endif
	old_default_margin = default_margin
	old_female_frequency = female_frequency
	old_male_frequency = male_frequency
	old_left_male_pitch = left_male_pitch
	old_right_male_pitch = right_male_pitch
	old_left_female_pitch = left_female_pitch
	old_right_female_pitch = right_female_pitch
	settings_ok = 0					; variable to check the settings values
	while !settings_ok
		beginPause: "Choose the settings"
			comment: "Change the margin for this word."
			positive: "Margin", remembered_margin
			comment: "Remember margin settings?"
			boolean: "Remember margin", remember_margin
			comment: "Change the default margin"
			positive: "Default margin", default_margin
			comment: "Choose the max frequency (Hz) for female speakers"
			natural: "Female frequency", female_frequency
			comment: "Choose the max frequency (Hz) for male speakers"
			natural: "Male frequency", male_frequency
			natural: "left female pitch", left_female_pitch
			natural: "right female pitch", right_female_pitch
			natural: "left male pitch", left_male_pitch
			natural: "right male pitch", right_male_pitch
		clicked = endPause: "Cancel", "Continue", 2, 1
		@check_settings
	endwhile
	if clicked = 2 and remember_margin = 1
		remembered_margin = margin
	endif
endproc    # ----------  end of procedure choose_settings  ----------

#===  PROCEDURE  ===============================================================
#         NAME: check_settings
#  DESCRIPTION: check whether the settings chosen by the user are correct
#  PARAMETER 1: ---
#===============================================================================
procedure check_settings
	#-----------------------------------------------------------------------
	# Check whether margin does not exceed the limit
	#-----------------------------------------------------------------------
	if margin > 49
		beginPause: "Invalid parameter value"
			comment: "Margin has to be equal to or smaller than 49 %!"
		clicked = endPause: "OK", 1, 1
	#-----------------------------------------------------------------------
	# Check whether margin does not exceed the limit
	#-----------------------------------------------------------------------
	elif default_margin > 49
		beginPause: "Invalid parameter value"
			comment: "Default margin has to be equal to or smaller than 49 %!"
		clicked = endPause: "OK", 1, 1
		default_margin = old_default_margin
	#-----------------------------------------------------------------------
	# Check whether the number of formants does not exceed the limit
	#-----------------------------------------------------------------------
	elif n_formants > max_n_formants
		beginPause: "Invalid parameter value"
			comment: "The number of formants cannot be greater than
			... 'max_n_formants'."
		clicked = endPause: "OK", 1, 1
	else
		settings_ok = 1
	endif
endproc    # ----------  end of procedure check_settings  ----------

#===  PROCEDURE  ===============================================================
#         NAME: to_spectrogram
#  DESCRIPTION: create a spectrogram from the extract
#  PARAMETER 1: ---
#===============================================================================
procedure to_spectrogram
	selectObject: extract'i'_'s'
	spectrogram'i'_'s' = noprogress To Spectrogram: 0.005, max_frequency, 0.002,
	... 20, "Gaussian"
endproc    # ----------  end of procedure to_spectrogram  ----------

#===  PROCEDURE  ===============================================================
#         NAME: to_formant
#  DESCRIPTION: create a formant object from the extract
#  PARAMETER 1: ---
#===============================================================================
procedure to_formant
	selectObject: extract'i'_'s'
	formant'i'_'s' = noprogress To Formant (burg): 0, max_n_formants,
	... max_frequency, 0.025, 50
endproc    # ----------  end of procedure to_formant  ----------

#===  PROCEDURE  ===============================================================
#         NAME: to_pitch
#  DESCRIPTION: create a pitch object from from the extract
#  PARAMETER 1: ---
#===============================================================================
procedure to_pitch
	selectObject: extract'i'_'s'
	pitch'i'_'s' = noprogress To Pitch: 0, left_pitch, right_pitch
endproc    # ----------  end of procedure to_pitch  ----------

#===  PROCEDURE  ===============================================================
#         NAME: draw_formant_lines
#  DESCRIPTION: draw the lines indicating in which part the formants will be
#               measured
#  PARAMETER 1: ---
#===============================================================================
procedure draw_formant_lines
	#---------------------------------------------------------------------------
	# draw lines to show in which part of the vowel formants will be measured
	#---------------------------------------------------------------------------
	demo Select inner viewport: x_min_s, x_max_s, y_min_s, y_max_s
	demo Axes: 0, 100, 0, 100
	demo Dashed line
	demo Blue
	demo Line width: 2
	demo Draw line: f_start_line's', 0, f_start_line's', 100
	demo Draw line: f_end_line's', 0, f_end_line's', 100
	demo Text special: mid_line's', "centre", 105, "half", "Helvetica", 15, "0",
	... vowel's'$ + percent'i'_'s'$
	demo Green
	demo Draw line: v_start_line's', 0, v_start_line's', 100
	demo Draw line: v_end_line's', 0, v_end_line's', 100
	demo Solid line
	demo Black
	demoShow()
endproc    # ----------  end of procedure draw_formant_lines  ----------

#===  PROCEDURE  ===============================================================
#         NAME: write_default_margin
#  DESCRIPTION: Write to the screen the current default margin
#  PARAMETER 1: ---
#===============================================================================
procedure write_default_margin
	demo Select inner viewport: 0, 100,  0, 100
	demo Axes: 0, 100, 0, 100
	demo Paint rectangle: "{1, 1, 1}", x_m_rect1, x_m_rect2, y_m_rect1, y_m_rect2
	demo Text special: x_margin, "left", y_margin, "half", "Helvetica", 15, "0",
	... "Default margin: " + string$ (default_margin) + "\% "
endproc    # ----------  end of procedure write_default_margin  ----------

#===  PROCEDURE  ===============================================================
#         NAME: draw_spectrogram
#  DESCRIPTION: draw the spectrogram
#  PARAMETER 1: ---
#===============================================================================
procedure draw_spectrogram
	#---------------------------------------------------------------------------
	# draw the spectrogram in shades of grey and the formants in yellow
	#---------------------------------------------------------------------------
	demo Select inner viewport: x_min_s, x_max_s, y_min_s, y_max_s
	demo Axes: 0, 100, 0, 100
	demo Paint rectangle: "{1, 1, 1}", -12, 100, 0, 110
	demo Line width: 1
	selectObject: spectrogram'i'_'s'
	demo Paint: 0, 0, 0, 0, 100, "yes", 50, 6, 0, "no"
	selectObject: formant'i'_'s'
	demo Red
	demo Speckle size: 1.5
	demo Speckle: 0, 0, max_frequency, 30, "yes"
	selectObject: pitch'i'_'s'
	demo Cyan
	demo Line width: 2
	demo Draw: 0, 0, left_pitch, right_pitch, "no"
	demo Blue
	demo Speckle: 0, 0, left_pitch, right_pitch, "no"
	@draw_marked
endproc    # ----------  end of procedure draw_spectrogram  ----------

#===  PROCEDURE  ===============================================================
#         NAME: draw_buttons
#  DESCRIPTION: draw the buttons under the spectrogram figure
#  PARAMETER 1: ---
#===============================================================================
procedure draw_buttons
	demo Select inner viewport: 0, 100,  0, 100
	demo Axes: 0, 100, 0, 100
	if quit = 1
		demo Grey
	else
		demo Black
	endif
	#---------------------------------------------------------------------------
	# draw the quit button
	#---------------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button1_x1, button1_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button1_x1, button1_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button1_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button1$

	if quit = 1 or s = 1 or pause = 1
		demo Grey
	else
		demo Black
	endif
	#---------------------------------------------------------------------------
	# draw the Continue button
	#---------------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button2_x1, button2_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button2_x1, button2_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button2_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button2$

	if quit = 1
		demo Grey
	else
		demo Black
	endif
	#---------------------------------------------------------------------------
	# draw the Continue button
	#---------------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button3_x1, button3_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button3_x1, button3_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button3_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button3$

	if quit = 1 or pause = 1
		demo Grey
	else
		demo Black
	endif
	#-----------------------------------------------------------------------
	# draw the play button
	#-----------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button4_x1, button4_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button4_x1, button4_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button4_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button4$

	if quit = 1 or pause = 1
		demo Grey
	else
		demo Black
	endif
	#-----------------------------------------------------------------------
	# draw the mark button
	#-----------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button5_x1, button5_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button5_x1, button5_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button5_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button5$

	if quit = 1 or pause = 1
		demo Grey
	else
		demo Black
	endif
	#-----------------------------------------------------------------------
	# draw the settings button
	#-----------------------------------------------------------------------
	demo Paint rectangle: "{0.8, 0.8, 0.8}", button6_x1, button6_x2, y_t - y_t_offset, y_t +
	... y_t_offset
	demo Draw rectangle: button6_x1, button6_x2, y_t - y_t_offset, y_t + y_t_offset
	demo Text special: button6_t, "centre", y_t, "half", "Helvetica", 20, "0",
	... button6$

	demo Black
endproc    # ----------  end of procedure draw_buttons  ----------

#===  PROCEDURE  ===============================================================
#         NAME: draw_marked
#  DESCRIPTION: draw the symbol for the marked item
#  PARAMETER 1: ---
#===============================================================================
procedure draw_marked
	if marked'i'_'s' = 1
		#-----------------------------------------------------------------------
		# draw the spectrogram in shades of grey and the formants in yellow
		#-----------------------------------------------------------------------
		demo Select inner viewport: x_min_s, x_max_s, y_min_s, y_max_s
		demo Axes: 0, 100, 0, 100
		demo Paint rectangle: "{0.8, 0.8, 0.8}", 86.5, 99, 92, 98
		demo Red
		demo Text special: 93, "centre", 94.5, "half", "Helvetica", 15, "0", "%%MARKED%"
		demo Black
	endif
endproc    # ----------  end of procedure draw_marked  ----------

#===  PROCEDURE  ===============================================================
#         NAME: get_formants
#  DESCRIPTION: measure F1-FX in the specified region of the target vowels
#  PARAMETER 1: ---
#===============================================================================
procedure get_formants
	selectObject: formant'i'_'s'
	for f to n_formants
		f'f'_'s' = Get mean: f, f_start's', f_end's', "Hertz"
	endfor
	#-----------------------------------------------------------------------
	# if formants 1-3 are measured, calculate the rations f2/f1 and f3/f2
	#-----------------------------------------------------------------------
	if n_formants > 1
		for f from 2 to n_formants
			lower_f = f - 1 		; formant fX-1 with respect to formant fX
			f'f'_f'lower_f'_'s' = f'f'_'s' / f'lower_f'_'s'
		endfor
	endif
endproc    # ----------  end of procedure get_formants  ----------

#===  PROCEDURE  ===============================================================
#         NAME: get_pitch
#  DESCRIPTION: measure F0 in the specified region of the target vowels
#  PARAMETER 1: --
#===============================================================================
procedure get_pitch
	selectObject: pitch'i'_'s'
	f0_'s' = Get mean: f_start's', f_end's', "Hertz"
endproc    # ----------  end of procedure get_pitch  ----------

#===  PROCEDURE  ===============================================================
#         NAME: write_results
#  DESCRIPTION: write the results to the results table and save it
#  PARAMETER 1: --
#===============================================================================
procedure write_results
	#---------------------------------------------------------------------------
	# measure the formants
	#---------------------------------------------------------------------------
	@get_formants
	@get_pitch
	selectObject: results'i'
	Set string value: s, "speaker", speaker$
	Set string value: s, "word", word's'$
	if get_voicing = 1
		Set string value: s, "voicing", voicing's'$
	endif
	Set string value: s, "vowel", vowel's'$
	Set string value: s, "F0", fixed$ (f0_'s', decimals)
	for f to n_formants
		Set string value: s, "F" + string$ (f), fixed$ (f'f'_'s', decimals)
	endfor
	#---------------------------------------------------------------------------
	# write the ratios of f2/f1, f3/f2, etc.
	#---------------------------------------------------------------------------
	for f from 2 to n_formants
		lower_f = f - 1 		; formant fX-1 with respect to formant fX
		.column$ = "F" + string$ (f) + "/F" + string$ (lower_f)
		Set string value: s, .column$, fixed$ (f'f'_f'lower_f'_'s', decimals)
	endfor
	#
	Set string value: s, "duration", fixed$ (v_duration's', decimals)
	Set numeric value: s, "proportion", percent'i'_'s'
	if suffix_length > 0
		Set string value: s, "position", position's'$
	endif
	Set numeric value: s, "marked", marked'i'_'s'
	Save as tab-separated file: results_dir$ + speaker$ + ".csv"
endproc    # ----------  end of procedure write_results  ----------

#===  PROCEDURE  ===============================================================
#         NAME: write_means
#  DESCRIPTION: calculate and write the mean values for various measurements
#  PARAMETER 1: --
#===============================================================================
procedure write_means
	#---------------------------------------------------------------------------
	# calculate the means
	#---------------------------------------------------------------------------
	selectObject: results'i'
	is_marked = Search column: "marked", "1"
;	if is_marked
;		beginPause: "Marked sounds in annotation"
;			comment: "There are some marked sounds in the annotation."
;			comment: "Do you want to exclude them from the results?"
;		clicked = endPause: "Cancel", "Inspect", "Exclude", 3, 1
;		if clicked = 3
;			non_marked_results'i' = Extract rows where column (text): "marked",
;			... "is not equal to", "1"
;		elif clicked = 2
;			selectObject: results'i'
;			.nRows = Get number of rows
;			for .r to .nRows
;				selectObject: results'i'
;				value = Get value: .r, "marked"
;				if value = 1
;					selectObject: extract_textgrid'i'_'.r'
;					plusObject: extract'i'_'.r'
;					View & Edit
;					beginPause: "Inspect recording and textgird"
;						comment: "Inspect the recording and textgird and click
;						... the button to continue."
;					clicked = endPause: "Next", 1, 1
;				next_word = 1
;				endif
;			endfor
;		endif
;	endif

	selectObject: results'i'
	mean_f0 = Get mean: "F0"
	for f to n_formants			; Formant means
		mean_f'f' = Get mean: "F" + string$ (f)
	endfor
	for f from 2 to n_formants	; means of fX/fX-1
		lower_f = f - 1 		; formant fX-1 with respect to formant fX
		.column$ = "F" + string$ (f) + "/F" + string$ (lower_f)
		mean_f'f'_f'lower_f' = Get mean: .column$
	endfor
	mean_duration = Get mean: "duration"
	#---------------------------------------------------------------------------
	# write the means to the table
	#---------------------------------------------------------------------------
	selectObject: final_results
	Set string value: i, "speaker", speaker$
	Set string value: i, "F0", fixed$ (mean_f0, decimals)
	for f to n_formants
		Set string value: i, "F" + string$ (f), fixed$ (mean_f'f', decimals)
	endfor
	#---------------------------------------------------------------------------
	# write the ratios of f2/f1, f3/f2, etc.
	#---------------------------------------------------------------------------
	for f from 2 to n_formants
		lower_f = f - 1 		; formant fX-1 with respect to formant fX
		.column$ = "F" + string$ (f) + "/F" + string$ (lower_f)
		Set string value: i, .column$, fixed$ (mean_f'f'_f'lower_f', decimals)
	endfor
	Set string value: i, "duration", fixed$ (mean_duration, decimals)
	Save as tab-separated file: results_dir$ + "final_results.csv"
endproc    # ----------  end of procedure write_means  ----------

#===  PROCEDURE  ===============================================================
#         NAME: play_extract
#  DESCRIPTION: play the current extract
#  PARAMETER 1: ---
#===============================================================================
procedure play_extract
	selectObject: extract'i'_'s'
	asynchronous Play
endproc    # ----------  end of procedure play_extract  ----------

#===  PROCEDURE  ===============================================================
#         NAME: gender
#  DESCRIPTION: assign values depending on the gender of the speaker
#  PARAMETER 1: ---
#===============================================================================
procedure gender
	#---------------------------------------------------------------------------
	# determine the gender of the speaker from the file name
	#---------------------------------------------------------------------------
	gender$ = right$ (speaker$, 1)
	if gender$ = "m"
		gender = 1
	elif gender$ = "f"
		gender = 2
	else
		beginPause: "Choose gender of the speaker"
			comment: "The gender of the speaker cannot be determined from the
			... textgrid!"
			comment: "The last character before the extension should be either
			... ""m"" or ""f"","
			comment: "e.g., john_m.TextGrid or mary_f.TextGrid."
			optionMenu: "Gender", 1
				option: "male"
				option: "female"
		clicked = endPause: "OK", 1
	endif
	#---------------------------------------------------------------------------
	# assign values
	#---------------------------------------------------------------------------
	if gender = 1
		max_frequency = male_frequency
		left_pitch = left_male_pitch
		right_pitch = right_male_pitch
	elif gender = 2
		max_frequency = female_frequency
		left_pitch = left_female_pitch
		right_pitch = right_female_pitch
	endif
endproc    # ----------  end of procedure gender  ----------

#===  PROCEDURE  ===============================================================
#         NAME: remove_initial_files
#  DESCRIPTION: remove files created by the script, which are not neede anymore,
#               and restore the selection of files in the object window
#  PARAMETER 1: ---
#===============================================================================
procedure remove_initial_files
	#---------------------------------------------------------------------------
	# check which objects are selected
	#---------------------------------------------------------------------------
	selectedItems = numberOfSelected ()
	for i to selectedItems
		sel'i' = selected (i)
	endfor
	#
	#---------------------------------------------------------------------------
	# make a list of all objects
	#---------------------------------------------------------------------------
	select all
	allItems = numberOfSelected ()
	for i to allItems
		object'i' = selected (i)
	endfor
	#
	#---------------------------------------------------------------------------
	# remove the appropriate objects
	#---------------------------------------------------------------------------
	for i to allItems
		if object'i' = stimuli
			removeObject: stimuli
		endif
		if object'i' = list_textgrids
			removeObject: list_textgrids
		endif
	endfor
	#
	#---------------------------------------------------------------------------
	# make a list of the remaining objects
	#---------------------------------------------------------------------------
	select all
	remainingItems = numberOfSelected ()
	for i to remainingItems
		rem'i' = selected (i)
	endfor
	#
	#---------------------------------------------------------------------------
	# restore the selection of the objects before removing
	#---------------------------------------------------------------------------
	selectObject ()
	for i to remainingItems
		for j to selectedItems
			if rem'i' = sel'j'
				plusObject: sel'j'
			endif
		endfor
	endfor
endproc    # ----------  end of procedure remove_initial_files  ----------

#-------------------------------------------------------------------------------
# Repair
#-------------------------------------------------------------------------------
# provide an explanation of how the script works!

# Changing settings:
# if old_frequency <> max_frequency
# redraw and rewrite only if changed

# if the last margin selection was wrong (more than 49 etc.) enable cancelling
# without warning

#-------------------------------------------------------------------------------
# TODO
#-------------------------------------------------------------------------------
# Add indication of absolute vowel duration below the spectrogram.
