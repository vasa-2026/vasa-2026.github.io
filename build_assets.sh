#!/bin/bash
# Regenerate static/images/ and static/interactive/ from the paper sources.
# Everything this writes is committed, so you only need this when a figure or
# an example run changes upstream.
#
#   VASA_PKG=path/to/arxiv_package VASA_REPO=path/to/VASA ./build_assets.sh
#
# Requires pdflatex, pdftoppm (poppler) and magick (ImageMagick).
set -euo pipefail

PKG=${VASA_PKG:-../ICLR2027/arxiv_package}
REPO=${VASA_REPO:-../VASA-release}
SITE=$(cd "$(dirname "$0")" && pwd)
IMG="$SITE/static/images"

mkdir -p "$IMG/plots" "$SITE/static/interactive"

# --- Vector diagrams: PDF -> PNG. -r 200 gives roughly twice the on-page width
# so the figures stay sharp on retina displays.
pdf2png () { pdftoppm -png -r 200 -singlefile "$1" "$2"; }
pdf2png "$PKG/figures/fig_model_v2.pdf"       "$IMG/method"
pdf2png "$PKG/figures/fig_walkthrough_v3.pdf" "$IMG/walkthrough"
pdf2png "$PKG/figures/fig_instruction_v4.pdf" "$IMG/pars"
pdf2png "$PKG/figures/fig_reason_vs_iou.pdf"  "$IMG/plots/reason_vs_iou"

# --- Figures the paper assembles in LaTeX from many images. Each one is
# compiled on its own from the paper source, without its caption, so the page
# shows exactly what the paper shows.
texfig () {  # tex-body  output-stem  [jpg|png]
  local work; work=$(mktemp -d)
  {
    cat <<'TEX'
\documentclass[border=1pt]{standalone}
\usepackage[T1]{fontenc}
\usepackage{times}
\usepackage{xcolor}
\input{preamble}
\begin{document}
% After \begin{document}, because the caption package installs its own
% \caption there and would undo an earlier redefinition.
\setlength{\textwidth}{5.5in}\setlength{\linewidth}{5.5in}
\renewenvironment{figure}[1][]{}{}
\renewenvironment{figure*}[1][]{}{}
\renewcommand{\caption}[1]{}
\renewcommand{\label}[1]{}
\renewcommand{\cite}[1]{}
% A fixed-width box, the paper's text width, so spacing inside the figure
% keeps the size it has in the paper instead of collapsing to nothing.
\begin{minipage}{5.5in}\centering
TEX
    printf '%s\n' "$1" '\end{minipage}' '\end{document}'
  } > "$work/fig.tex"
  (cd "$PKG" && pdflatex -interaction=nonstopmode -halt-on-error \
     -output-directory="$work" "$work/fig.tex" >"$work/build.log" 2>&1) \
    || { tail -20 "$work/build.log"; exit 1; }
  pdftoppm -png -r 300 -singlefile "$work/fig.pdf" "$work/fig"
  # The box is wider than most figures; trim the margin it leaves.
  magick "$work/fig.png" -trim +repage -bordercolor white -border 6 "$work/fig.png"
  # Photos compress well as JPEG; plots keep their edges as PNG.
  if [ "${3:-jpg}" = png ]; then cp "$work/fig.png" "$2.png"
  else magick "$work/fig.png" -quality 92 "$2.jpg"; fi
  rm -rf "$work"
}
PKG=$(cd "$PKG" && pwd)
texfig '\input{floats/fig_teaser}'      "$IMG/teaser"
texfig '\input{floats/fig_qualitative}' "$IMG/qualitative"

# The query-detail example shares its float with a table, which the page sets
# as HTML, so only the image row is compiled. Keep it in step with
# floats/tab_ablation_instruction.tex.
texfig '\small
\newcommand{\squareimage}[1]{\includegraphics[width=0.24\textwidth, height=0.24\textwidth]{#1}}
\newcommand{\close}{\hspace{1pt}}
\resizebox{0.59\textwidth}{!}{
\begin{tabular}{@{}c@{\close}c@{\close}c@{\close}c@{}}
\ssamthreeagent short & \ssamthreeagent long & \sname short & \sname long \\
\squareimage{figures/fig_ablation_instruction/7053_sam3agent_short.pdf} &
\squareimage{figures/fig_ablation_instruction/7053_original.pdf} &
\squareimage{figures/fig_ablation_instruction/7053_ours_short.pdf} &
\squareimage{figures/fig_ablation_instruction/7053_ours_long.pdf}
\end{tabular}
}' "$IMG/query_detail"

# --- The four capability panels are laid out by the page with gaps between
# them; the paper packs them too tightly for a screen.
for p in mmmu_pro hle tokens cost; do
  pdf2png "$PKG/figures/Figure5_$p.pdf" "$IMG/plots/$p"
done

# --- Social banner: input, SAM3 Agent and VASA on the exclusion query, side by
# side at the 1200x630 size link previews expect.
T="$PKG/figures/fig_teaser"
cell () { magick "$1" -resize 370x370^ -gravity center -extent 370x370 \
  -bordercolor black -border 10 "$2"; }
cell "$T/pipi.jpg"             "$IMG/_b1.png"
cell "$T/pipi_sam3agent_3.jpg" "$IMG/_b2.png"
cell "$T/pipi_ours_3.png"      "$IMG/_b3.png"
magick "$IMG/_b1.png" "$IMG/_b2.png" "$IMG/_b3.png" +append -background black \
  -gravity center -extent 1200x630 -quality 90 "$IMG/banner.jpg"
rm -f "$IMG"/_b?.png

# --- Favicon: a green V on black, drawn as shapes so it stays legible at 16px.
magick -size 512x512 xc:none -fill '#0b0b0b' -draw 'roundrectangle 0,0 511,511 96,96' \
  -fill '#43b78d' -draw 'polygon 88,112 184,112 256,322 328,112 424,112 304,420 208,420' \
  "$IMG/android-chrome-512x512.png"
magick "$IMG/android-chrome-512x512.png" -resize 192x192 "$IMG/android-chrome-192x192.png"
magick "$IMG/android-chrome-512x512.png" -resize 180x180 "$IMG/apple-touch-icon.png"
magick "$IMG/android-chrome-512x512.png" -resize 32x32   "$IMG/favicon-32x32.png"
magick "$IMG/android-chrome-512x512.png" -resize 16x16   "$IMG/favicon-16x16.png"
magick "$IMG/favicon-32x32.png" "$IMG/favicon-16x16.png" "$IMG/favicon.ico"

# --- The embedded run replays are trace.html verbatim from the released runs.
cp "$REPO/outputs/pipi-head/trace.html"    "$SITE/static/interactive/run-head.html"
cp "$REPO/outputs/pipi-contact/trace.html" "$SITE/static/interactive/run-contact.html"
cp "$REPO/outputs/pipi-strip/trace.html"   "$SITE/static/interactive/run-stripes.html"

du -sh "$IMG" "$SITE/static/interactive"
