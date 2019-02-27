NAME = thesis
CHAPTERS_DIR = chapters
APPENDIX_FILES = $(wildcard $(CHAPTERS_DIR)/appendix*.tex $(CHAPTERS_DIR)/appendix*.md)
APPENDICES = $(sort $(notdir $(basename $(APPENDIX_FILES))))
CHAPTER_FILES = $(filter-out $(APPENDIX_FILES), $(wildcard $(CHAPTERS_DIR)/*.tex $(CHAPTERS_DIR)/*.md))
CHAPTERS = $(sort $(notdir $(basename $(CHAPTER_FILES))))
DIAGRAMS_DIR = diagrams
BUILD_DIR = build
BIB = literature.bib

CHAPTERS_TEX = $(or $(CHAPTERS:%=$(BUILD_DIR)/%.tex),/dev/null)
APPENDICES_TEX = $(or $(APPENDICES:%=$(BUILD_DIR)/%.tex),/dev/null)
CONTENT_TEX = $(BUILD_DIR)/$(NAME)_content.combined.tex
ATTACHMENTS_TEX= $(BUILD_DIR)/$(NAME)_attachments.combined.tex
PDFL_FLAGS = -jobname $(NAME)
PANDOC_MD_FLAGS = -f markdown -t latex --top-level-division=chapter --biblatex --biblio $(BIB)

all: $(NAME).pdf

# LaTeX must be run twice to get references right
$(NAME).pdf: $(CONTENT_TEX) $(ATTACHMENTS_TEX) $(NAME).bbl $(NAME).xmpdata
	pdflatex $(PDFL_FLAGS) $(NAME).tex
	makeindex -s $(NAME).ist -t $(NAME).glg -o $(NAME).gls $(NAME).glo
	pdflatex $(PDFL_FLAGS) $(NAME).tex
	pdflatex $(PDFL_FLAGS) $(NAME).tex

$(CONTENT_TEX): $(BUILD_DIR) $(CHAPTERS_TEX)
	cat $(CHAPTERS_TEX) > $@
	
$(ATTACHMENTS_TEX): $(BUILD_DIR) $(APPENDICES_TEX)
	cat $(APPENDICES_TEX) > $@

$(BUILD_DIR):
	mkdir -p "$@"

$(BUILD_DIR)/%.tex: $(CHAPTERS_DIR)/%.tex $(wildcard $(DIAGRAMS_DIR)/*)
	cat $< > $@

$(BUILD_DIR)/%.tex: $(CHAPTERS_DIR)/%.md $(wildcard $(DIAGRAMS_DIR)/*)
	cat $< | pandoc $(PANDOC_MD_FLAGS) > $@

$(NAME).bbl: $(BIB) $(CONTENT_TEX)
	rm -f $(NAME).bbl
	pdflatex $(PDFL_FLAGS) $(NAME).tex
	biber $(NAME)

clean:
	- rm -rf $(BUILD_DIR)
	- rm -f *.log *.dvi *.aux *.toc *.lof *.lot *.out *.ist *.glg *.gls *.glo
	- rm -f *.glsdefs *.acn
	- rm -f $(NAME).pdf
	- rm -f $(NAME).bbl $(NAME).blg $(NAME).bcf $(NAME).run.xml
