# Everyday commands. `make` alone renders everything into public/.
.PHONY: all render html pdf check new preview extension clean

all: check render

render:              ## website + every PDF and Word file, into public/
	quarto render

html:                ## website only (fast)
	quarto render --to house-html

pdf:                 ## one document's PDF, e.g. make pdf DOC=analysis/2026-10-foo/index.qmd
	quarto render $(DOC) --to house-pdf

preview:             ## live-reloading local preview of the website
	quarto preview

check:               ## cross-reference checks, no render needed
	python3 scripts/check-refs.py

new:                 ## start an analysis: make new SLUG=my-topic TITLE="My topic"
	sh scripts/new-analysis.sh $(SLUG) $(if $(TITLE),"$(TITLE)")

extension:           ## install or upgrade the house style extension
	quarto add scattercode/quarto-house --no-prompt

clean:
	rm -rf public .quarto
	find . -name "*_files" -type d -prune -exec rm -rf {} +
