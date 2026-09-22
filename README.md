# Climate Taxonomy Brain

A one-page prototype: paste or type any text and see which words come from the
CGIAR climate adaptation taxonomy, which are synonyms of an agreed term, and which
pathway elements (hazard, intervention, system, result) the text names.

**Live page:** https://mlolita26.github.io/climate-taxonomy-brain/

## How it works

Everything about the taxonomy happens in R; the page's JavaScript only does the
live matching in the browser and never needs to change when the data changes.

| File | What it is |
| --- | --- |
| `build_brain.R` | The script. Reads the taxonomy, tidies it with dplyr, writes the page. |
| `data/taxonomy_v5.json` | The climate adaptation taxonomy, version 5 (739 concepts, built 2026-09-04). |
| `template/brain.html` | The page layout and the matching code, with placeholders for the data. |
| `docs/index.html` | The built page. GitHub Pages serves this folder. |

## Rebuild the page

```
Rscript build_brain.R
```

Needs R with `dplyr`, `purrr`, `tidyr`, `stringr`, `jsonlite`, `readr`.
Commit `docs/index.html` and the live page updates.

## Use it for another taxonomy

Replace `data/taxonomy_v5.json` with a file that has, for each concept, an `id`,
a `term`, `synonyms`, a `facet` and a `definition`, adjust the column list at the
top of `build_brain.R`, and rebuild. The matching is generic: labels and synonyms,
plural- and hyphen-insensitive, longest phrase first.

## What it does not do (yet)

This is tier 1: the taxonomy as data, matched on words. It does not check with a
model that a matched term is really meant in context, and it does not surface
words that match nothing as candidate new terms. Both already run in the PRMS
tagging pipeline of the Climate Adaptation Activator and are the next tier.
