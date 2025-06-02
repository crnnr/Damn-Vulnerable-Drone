# Makefile for DVD Documentation

# LaTeX compiler
LATEX = pdflatex
BIBTEX = bibtex

# Source files
SOURCES = ctf-walkthrough.tex system-architecture.tex security-analysis.tex

# Output directory
OUTDIR = build

# PDF targets
PDFS = $(SOURCES:.tex=.pdf)

# Default target
all: $(PDFS)

# Create output directory
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Compile individual documents
%.pdf: %.tex | $(OUTDIR)
	$(LATEX) -output-directory=$(OUTDIR) $<
	$(LATEX) -output-directory=$(OUTDIR) $<  # Second pass for references
	mv $(OUTDIR)/$@ .

# Build all documents
build-all: clean $(PDFS)
	@echo "All documents built successfully"

# Clean auxiliary files
clean:
	rm -rf $(OUTDIR)
	rm -f *.aux *.log *.toc *.out *.bbl *.blg *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz

# Clean everything including PDFs
distclean: clean
	rm -f *.pdf

# Watch for changes and rebuild
watch:
	while inotifywait -e modify *.tex; do make all; done

# Create HTML versions (requires tex4ht)
html: $(SOURCES)
	for file in $(SOURCES); do \
		htlatex $$file "html,2,info" "" "" "-interaction=nonstopmode"; \
	done

# Package documentation for distribution
package: build-all
	mkdir -p dvd-docs
	cp *.pdf dvd-docs/
	cp README.md dvd-docs/
	tar czf dvd-documentation.tar.gz dvd-docs/
	rm -rf dvd-docs/

# Help target
help:
	@echo "Available targets:"
	@echo "  all        - Build all PDF documents"
	@echo "  build-all  - Clean and build all documents"
	@echo "  clean      - Remove auxiliary files"
	@echo "  distclean  - Remove all generated files"
	@echo "  html       - Generate HTML versions"
	@echo "  package    - Create documentation package"
	@echo "  watch      - Watch for changes and rebuild"
	@echo "  help       - Show this help message"

.PHONY: all build-all clean distclean html package watch help