# 1. Overview {#sec-overview}

*Replace this chapter with your own. It shows the conventions.*

The platform is a set of Azure Databricks environments, each holding three
workspaces, built from Declarative Automation Bundles (DABs, formerly
Databricks Asset Bundles) and governed through Unity Catalog.

## 1.1 Reading this document {#sec-overview-reading}

Chapters keep manual numbers in their headings so they read correctly when
replicated to a wiki; the build strips them and numbers the rendered output
itself. Refer to other chapters and sections with cross-references rather
than typed numbers, so the number cannot drift — the environments are
described in @sec-environments, for instance, and the glossary of terms
in @sec-glossary.

## 1.2 Terminology {#sec-overview-terminology}

An *environment* is dev, ppr or prd. A *workspace* is sandbox, staging or
live. An environment contains three workspaces, never the other way round.
