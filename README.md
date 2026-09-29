# VASA project page

Source for <https://vasa-2026.github.io/> — the project page for **VASA: Vision Harnessing Agent
for Open Ad-hoc Segmentation** (Zilin Wang, Stella X. Yu, University of Michigan).

Paper: <https://arxiv.org/abs/2605.19410> · Code: <https://github.com/Wayne2Wang/VASA>

## Editing

Everything is static. `index.html` holds the content, `static/css/vasa.css` holds the
additions on top of the template's stylesheet. There is no build step for the page itself —
edit and reload.

To preview locally:

```bash
python3 -m http.server 8811
```

## Regenerating assets

`static/images/` and `static/interactive/` are generated from the paper sources and the
released example runs, and are committed. Rerun only when a figure or an example run changes:

```bash
VASA_PKG=../ICLR2027/arxiv_package VASA_REPO=../VASA-release ./build_assets.sh
```

It needs `pdflatex`, `pdftoppm` (poppler) and `magick` (ImageMagick). The teaser and
qualitative figures are compiled from the paper's own LaTeX floats, so they match the paper. The three files under
`static/interactive/` are `trace.html` copied verbatim from the released runs, so the replay
embedded in the page is exactly what the released code produces.

## Credits

Built on the [Academic Project Page Template](https://github.com/eliahuhorwitz/Academic-project-page-template),
adopted from the [Nerfies](https://nerfies.github.io) project page, and shares its layout with our
earlier [OAK project page](https://oak-2025.github.io/).

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This website is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.
