# build_brain.R
# Builds docs/index.html: a page that highlights climate taxonomy terms as you type.
# Everything about the taxonomy happens here in R. The page's JavaScript only does
# the live matching in the browser and never needs to change when the data changes.
#
# Run from the repository root:   Rscript build_brain.R

library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(jsonlite)

# 1. Read the taxonomy -----------------------------------------------------------

raw <- read_json("data/taxonomy_v5.json")

concepts <- tibble(
  id                = map_chr(raw$concepts, "id"),
  term              = map_chr(raw$concepts, "term"),
  synonyms          = map(raw$concepts, \(c) I(as.character(unlist(c$synonyms)))),  # I() keeps a single synonym as a list in JSON
  facet             = map_chr(raw$concepts, "facet"),
  stage             = map_chr(raw$concepts, "pathway_stage",   .default = ""),
  definition        = map_chr(raw$concepts, "definition",      .default = ""),
  definition_source = map_chr(raw$concepts, "definition_source", .default = ""),
  parent_id         = map_chr(raw$concepts, "parent_id",       .default = NA_character_),
  adaptation        = map_chr(raw$concepts, c("adaptation", "tag")),
  condition         = map_chr(raw$concepts, c("adaptation", "condition")),
  is_hazard         = map_lgl(raw$concepts, c("derived", "is_hazard")),
  provenance        = map_chr(raw$concepts, c("provenance", "source"), .default = ""),
  relations         = map(raw$concepts, \(c) map(c$relations, \(r) list(type = r$type, target = r$target)))
)

# 2. One row per word people might actually write: the preferred term and every synonym

labels <- bind_rows(
  concepts |> transmute(id, label = term, kind = "term"),
  concepts |> select(id, synonyms) |> unnest(synonyms) |> transmute(id, label = synonyms, kind = "synonym")
) |>
  filter(label != "") |>
  distinct()

# 3. Homonym guards: words that stay in the vocabulary but must not fire in these contexts
#    (from tagging_disambiguation_guards.csv in the v5 cleanup)

guards <- tribble(
  ~id,       ~pattern,
  "INT_160", "\\bCOP ?\\d+\\b|Conference of the Parties",
  "INT_321", "\\b(yield|research|capacity|knowledge|data|evidence|gender)\\s+gaps?\\b|\\bgap analysis\\b",
  "OTC_136", "\\bregions?\\s+of\\s+interest\\b|\\bROIs?\\b(?=[^.]*\\b(image|imagery|raster|pixel|remote sensing|satellite)\\b)",
  "INT_274", "\\bagro[- ]?ecological\\s+(zone|zoning|zonation|region)",
  "INT_329", "\\b(repair|machine|machinery|welding|carpentry|processing|fabrication|maintenance|artisan|tailoring|blacksmith)\\s+workshops?\\b|\\bworkshops?\\s+(floor|equipment|tools|premises|building|space)\\b"
)

# 4. Sample texts shown in the page (two are real 2025 PRMS results)

samples <- tribble(
  ~name, ~text,
  "PRMS result: digital advisory, Ghana",
  "The innovation is a digital advisory tool designed to provide cropping calendar advisories to farmers in Northern Ghana. This platform delivers a comprehensive suite of agronomic advisories, including optimal planting times, thinning schedules, fertilizer application guidelines, weeding, pest management strategies, and harvest and postharvest operations. Aimed at enhancing resource use efficiency and mitigating drought risks, the tool empowers farmers to become more resilient against climate variability. It is intended for use by farmers seeking to optimize their agricultural practices and improve crop yield and sustainability in the challenging climatic conditions of Northern Ghana.",
  "PRMS result: genebank collecting mission",
  "Responding to growing demand from genebank users, CIAT genebank conducted a third collecting mission in New Mexico and Texas, focusing on heat- and drought-tolerant Phaseolus species (e.g., P. acutifolius, P. filiformis). The mission was led by USDA in collaboration with New Mexico State University. 23 new populations were collected, as the previous rain season was sustained and significant.",
  "Example with no hazard named",
  "The project distributed improved maize seed to 2,000 smallholder farmers in Malawi through agro-dealers, together with training on good agricultural practices. Yields increased by 20 percent on participating farms and household income improved. A yield gap analysis was completed for the region."
)

# 5. A few numbers for the page header and footer

meta <- list(
  schema      = raw$meta$schema,
  built_at    = raw$meta$built_at,
  builder     = raw$meta$builder,
  n_concepts  = nrow(concepts),
  n_synonyms  = sum(labels$kind == "synonym"),
  n_relations = sum(lengths(concepts$relations)),
  page_built  = format(Sys.Date())
)

# 6. Put the data into the page template and write docs/index.html -----------------

as_json <- function(x) toJSON(x, auto_unbox = TRUE, na = "null", null = "null")

inject <- function(html, placeholder, value) {
  parts <- str_split_fixed(html, fixed(placeholder), 2)
  paste0(parts[1], value, parts[2])
}

page <- readr::read_file("template/brain.html") |>
  inject("__META__",     as_json(meta)) |>
  inject("__CONCEPTS__", as_json(concepts)) |>
  inject("__LABELS__",   as_json(labels)) |>
  inject("__GUARDS__",   as_json(guards)) |>
  inject("__SAMPLES__",  as_json(samples))

dir.create("docs", showWarnings = FALSE)
readr::write_file(page, "docs/index.html")
invisible(file.create("docs/.nojekyll"))   # tells GitHub Pages to serve the folder as-is

cat(sprintf("Wrote docs/index.html: %d concepts, %d synonyms, %d relations (%.0f KB)\n",
            meta$n_concepts, meta$n_synonyms, meta$n_relations, file.size("docs/index.html") / 1024))
