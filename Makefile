# LaTeX -*-Makefile-*-
#
# Here's what this Makefile gives you:
#
# make dvi	- Generates the DVI file, suitable for previewing
# make ps	- Generates a postscript file suitable for printing
# make pdf	- Generates a PDF file suitable for viewing/printing
# make all	- Generates DVI, postscript, and PDF files
# make clean	- Removes some intermediate files
# make cleanall	- Removes all generated PS, DVI, and PDF files
#
#
# INSTRUCTIONS:
# -------------
#
# This first section contains macros whose values that you need to
# fill in.
#

# MAIN_TEX: In order to build your DOCUMENT, fill in the
# MAIN_TEX macro with the name of your main .tex file -- the one that
# you invoke LaTeX on.

MAIN_TEX	= report.tex
SRC_TEX		= $(filter-out $(MAIN_TEX),$(wildcard *.tex))

# CHAP_CITE_TEX: Some documents require separate bibliographies for each chapter.
# If your rocuments only requires a single bibliography at
# the end of the work, leave this macro blank and go on to
# OTHER_SRC_FILES, below.

# If your DOCUMENT does require chapter bibliographies, put the
# filenames of your chapters in this macro (and do *not* list them
# again in OTHER_SRC_FILES, below).  You will also need to use the
# "chapterbib" classfile -- see the example.tex for an
# example.  You will also need to remove the \bibliographystyle{} and
# \bibliography{} commands from the top-level file
# (example.tex), and append them to the end of the files
# listed in CHAP_CITE_TEX.

CHAP_CITE_TEX	= $(shell grep -l \bibliography $(SRC_TEX))

# OTHER_SRC_FILES: Put in the names of all the other files that your
# thesis depends on (e.g., other .tex files, .eps figures, etc.) in
# the OTHER_SRC_FILES macro.  This is ensure that whenever one of the
# "other" files changes, "make" will rebuild your paper properly.  You
# should *not* list any files in this macro that were already listed
# in CHAP_CITE_TEX, above.

OTHER_SRC_FILES	= $(filter-out $(CHAP_CITE_TEX),$(SRC_TEX)) $(wildcard *.bib *.png *.eps */*.png */*.eps)

# You should not need to change these, but just in case...

LATEX		= latex		#-interaction=nonstopmode
PDFLATEX	= pdflatex	# option under development
#DVIPS		= dvips
#DVIPS		= dvips -Pps -Ptype1
#DVIPS 		= dvips -Ppdf -G0
DVIPS		= dvips -j0 -Ppdf -u ps2pk -G0 -t a4 -D 1200 -Z -mode ljfzzz #http://mpa.itc.it/markus/highres_pdf.html
#PSPDF		= ps2pdf
PSPDF		= ps2pdf -sPAPERSIZE=a4 -dPDFSETTINGS=/prepress
EPSPDF		= epstopdf
BIBTEX		= bibtex

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

.SUFFIXES: .tex .dvi .pdf .ps .eps .bbl

MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)
MAIN_BBL	= $(MAIN_TEX:.tex=.bbl)
CHAP_BBL	= $(CHAP_CITE_TEX:.tex=.bbl)

#
# Some common target names
# Note that the default target is "dvi"
#

all: pdf
dvi: $(MAIN_DVI)
ps:  $(MAIN_PS)
pdf: $(MAIN_PDF)
ifneq ($(CHAP_BBL),)
  bbl: $(CHAP_BBL) $(filter %.bib,$(OTHER_SRC_FILES))
else
  bbl: $(MAIN_BBL) $(filter %.bib,$(OTHER_SRC_FILES))
endif

all: pdf 

debug: $(MAIN_TEX:.tex=.log)
	@grep -e 'Warning' -e 'Error' --color $< ||\
	echo "$* is OK"

test: $(MAIN_TEX:.tex=.log)
	@grep -e 'Warning: Reference' -e 'Warning: Citation' -e 'Warning: Label' \
	      -e 'undefined citations' -e 'undefined references' -e 'Rerun' --color $< ||\
	echo "$< is OK"

#
# Make the dependencies so that things build when they need to
#

$(MAIN_DVI): $(MAIN_TEX) $(CHAP_CITE_TEX) $(OTHER_SRC_FILES)
$(MAIN_PDF): $(MAIN_TEX) $(CHAP_CITE_TEX) $(OTHER_SRC_FILES)
$(MAIN_BBL): $(MAIN_TEX) $(CHAP_CITE_TEX) $(OTHER_SRC_FILES)
$(CHAP_BBL): $(MAIN_TEX) $(CHAP_CITE_TEX) $(OTHER_SRC_FILES)

#
# General rules
#

OTHER_SRC_FILES := $(OTHER_SRC_FILES:.eps=.pdf)

%.pdf:%.tex
	$(PDFLATEX) $*
	@-for N in 1 2 3 4 ; do \
	  if grep -e 'Warning: Reference' -e 'Warning: Citation' -e 'Warning: Label' \
	          -e 'undefined citations' -e 'undefined references' -e 'Rerun' --color $*.log; then \
	    $(MAKE) bbl ; \
	    $(PDFLATEX) $* ; \
	  fi ; \
	done

%.pdf:%.eps
	$(EPSPDF) $*.ps $*.pdf

%.ps:%.dvi
	$(DVIPS) -o $*.ps $*

%.bbl:%.tex %.aux
	@-echo "RUNNING BIBTEX ON FILE: $*"; \
	$(BIBTEX) $* | grep -ie "Error" -ie "Warning" -e "--line" -A1 --color; \
	if test -s $*.bbl; then \
	  sed "s/Technical [Rr]eport//" $*.bbl > tmp.$* ; \
	  mv tmp.$* $*.bbl; \
	fi

#
# Standard targets
#

clean:
	rm -f *~ *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out

cleanall: clean
	rm -f $(MAIN_PDF) $(MAIN_PS) $(MAIN_DVI)
