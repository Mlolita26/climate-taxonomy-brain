# Climate Taxonomy Brain

A one-page prototype: paste or type any text and see which words come from the
CGIAR climate adaptation taxonomy, which are synonyms of an agreed term, and whether
the text evidences a complete impact pathway, using the same element-count rule as
the PRMS tagging pipeline.

**Live page:** https://mlolita26.github.io/climate-taxonomy-brain/

## How it works

Everything about the taxonomy and the rule parameters lives in R; the page's
JavaScript only does the matching and counting in the browser and never needs to
change when the data changes.

| File | What it is |
| --- | --- |
| `build_brain.R` | The script. Reads the taxonomy, tidies it with dplyr, holds the rule parameters, writes the page. |
| `data/taxonomy_v5.json` | The climate adaptation taxonomy, version 5 (739 concepts, built 2026-09-04). |
| `template/brain.html` | The page layout, the matching code and the verdict engine, with placeholders for the data. |
| `docs/index.html` | The built page. GitHub Pages serves this folder. |
| `test_rule.js` | Runs the matcher and the rule on the built-in samples from the command line (`node test_rule.js`). |

## The rule

Mirrors `derive_verdicts()` in `PRMS_Tagging_v5.Rmd` and the decision-rule files:

1. An **adaptation-specific** term counts on its own (an anchor: drought, drip irrigation,
   early warning system).
2. An **adaptation-conditional** term (maize, farmer, yield) counts only through a qualifying
   relation to an anchor. The page checks the relations stored in the taxonomy first
   (`addresses`, `produces`, `applies-to`, ...). For the relations the pipeline's model reads
   from the text (`attributed-to`, `exposed-to`, `benefits-from`, `engaged-in`) the page uses a
   labelled proxy: the anchor appears in the same sentence. The proxy can be switched off.
3. Each counting term fills one pathway element: rationale, intervention, system/stakeholder,
   result. Cross-cutting concepts fill rationale only when specific; adoption terms fill nothing.
4. Distinct elements give the verdict: 4 Full (1.00), 3 Partial (0.75), 2 Partial (0.50),
   1 Minimal (0.25), 0 None. The mitigation axis runs in parallel with its own relations.

The rule's canonical example holds: "distributing fertilizer to raise maize yields" detects
six taxonomy terms and scores **None**, because none is linked to a hazard.

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
