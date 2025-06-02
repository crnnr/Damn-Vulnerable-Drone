# Damn Vulnerable Drone Documentation

This directory contains comprehensive LaTeX documentation for the DVD project.

## Document Structure

### 1. ctf-walkthrough.tex
Complete technical walkthrough for the CTF challenge including:
- Step-by-step attack methodology
- MITRE ATT&CK framework mapping
- Hands-on commands and scripts
- Educational explanations

### 2. system-architecture.tex
Detailed system design documentation covering:
- Container architecture and networking
- Component interactions
- Deployment configurations
- Technical specifications

### 3. security-analysis.tex
Comprehensive security analysis including:
- Vulnerability assessments
- Defensive strategies
- Compliance mapping
- Incident response procedures

## Building the Documentation

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt-get install texlive-full

# macOS with Homebrew
brew install --cask mactex

# Windows
# Download and install MiKTeX from https://miktex.org/
```

### Compilation
```bash
# Build individual documents
pdflatex ctf-walkthrough.tex
pdflatex system-architecture.tex
pdflatex security-analysis.tex

# Build all documents
make all

# Clean auxiliary files
make clean
```

### Dependencies
The documents require the following LaTeX packages:
- tikz (for diagrams)
- listings (for code blocks)
- longtable (for tables)
- hyperref (for links)
- xcolor (for colors)
- geometry (for layout)

## Document Maintenance

### Style Guidelines
- Use consistent formatting across all documents
- Include MITRE ATT&CK references where applicable
- Maintain technical accuracy and educational value
- Update version information regularly

### Updates
When updating the DVD system, ensure all documentation reflects:
- New container configurations
- Updated attack vectors
- Modified defensive measures
- Current compliance requirements

## Output Formats

The documentation can be generated in multiple formats:
- PDF (primary format)
- HTML (via tex4ht)
- EPUB (via pandoc conversion)

## Contributing

When contributing to documentation:
1. Maintain consistent LaTeX style
2. Test compilation before committing
3. Update cross-references as needed
4. Include proper citations and references