# Skill Catalog Reference

## Built-in Skills (Scientific Agent Skills)

### Data Science & ML

| Skill | Description | Triggers |
|-------|-------------|----------|
| `aeon` | Time series ML (classification, regression, forecasting) | time series, temporal data, sequential patterns |
| `scikit-learn` | ML with sklearn (classification, regression, clustering) | supervised learning, unsupervised learning, ML pipelines |
| `transformers` | Hugging Face Transformers (NLP, vision, audio) | AutoModel, pipelines, tokenizers, Trainer |
| `pytorch-lightning` | PyTorch Lightning (distributed training, callbacks) | LightningModule, Trainer, DDP, FSDP |
| `deepchem` | Molecular ML (ADMET, toxicity, MoleculeNet) | molecular property prediction, featurization |

### Bioinformatics & Genomics

| Skill | Description | Triggers |
|-------|-------------|----------|
| `scanpy` | Single-cell RNA-seq analysis (QC, clustering, DE) | scRNA-seq, single-cell, AnnData, UMAP |
| `anndata` | Annotated data matrices (.h5ad format) | .h5ad files, scverse ecosystem |
| `cellxgene-census` | CZ CELLxGENE Census queries | population-scale single-cell, atlas comparison |
| `bulk-rnaseq` | Bulk RNA-seq pipeline (FASTQ → DE → pathways) | RNA-seq, FASTQ, DESeq2, STAR, Salmon |
| `pathway-enrichment` | Pathway/GSEA analysis (GO, KEGG, Reactome) | enrichment analysis, GSEA, over-representation |
| `arboreto` | Gene regulatory network inference (GRNBoost2, GENIE3) | GRN, transcription factor targets, regulons |
| `biopython` | Molecular biology toolkit (sequences, BLAST, NCBI) | FASTA, GenBank, PDB, Entrez, phylogenetics |
| `bioservices` | 40+ bioinformatics services (UniProt, KEGG, ChEMBL) | cross-database queries, ID mapping |
| `pysam` | Genomic file workflows (SAM/BAM/VCF/FASTQ) | pileup, coverage, indexing, CRAM |
| `alphagenome` | AlphaGenome variant effect prediction (AVI, SHAP) | SNV prioritization, regulatory effects |

### Chemistry & Materials

| Skill | Description | Triggers |
|-------|-------------|----------|
| `rdkit` | Cheminformatics (SMILES, descriptors, fingerprints) | molecular manipulation, similarity, reactions |
| `pymatgen` | Materials analysis (structures, phase diagrams, MP) | crystal structures, Materials Project, symmetry |
| `cobrapy` | Constraint-based metabolic modeling (FBA, FVA) | metabolic engineering, flux analysis, SBML |
| `adaptyv` | Adaptyv Bio Foundry (protein experiments, BLI/SPR) | protein binding assays, screening experiments |

### Physics & Simulation

| Skill | Description | Triggers |
|-------|-------------|----------|
| `molecular-dynamics` | MD simulations (OpenMM, MDAnalysis) | protein MD, drug binding, RMSD/RMSF |
| `cirq` | Google quantum computing framework | Google hardware, noise modeling |
| `qiskit` | IBM quantum computing (circuits, runtime, QPU) | Qiskit 2.x, V2 primitives, IBM QPU |
| `astropy` | Astronomy/astrophysics (coordinates, FITS, WCS) | astronomical data analysis, cosmology |

### Statistics & Modeling

| Skill | Description | Triggers |
|-------|-------------|----------|
| `pymc` | Bayesian modeling (MCMC, VI, LOO/WAIC) | hierarchical models, probabilistic programming |
| `sympy` | Symbolic math (algebra, calculus, solving) | exact symbolic computation, code generation |
| `networkx` | Network/graph analysis (algorithms, visualization) | graphs, centrality, communities, pathfinding |

### Specialized Domains

| Skill | Description | Triggers |
|-------|-------------|----------|
| `analytical-method-validation` | ICH Q2(R2), USP <1225>, method validation | HPLC, LC-MS/MS, validation protocols |
| `clinical-decision-support` | Clinical decision support evaluation | research CDS, evidence profiles |
| `clinical-reports` | Clinical report structures (safety-bounded) | case reports, trial reports, safety reports |

## Utility Skills

| Skill | Description | Triggers |
|-------|-------------|----------|
| `context7` | Library documentation lookup | library docs, API reference, version info |
| `browser-use` | Browser automation via CDP | web scraping, testing, automation |
| `citation-management` | Citation management (OpenAlex, PubMed, Scholar) | BibTeX, DOI lookup, reference validation |
| `pdf` | PDF manipulation (read, merge, split, OCR) | PDF processing, text extraction |
| `docx` | Word document manipulation (.docx/.dotx) | document generation, editing |
| `pptx` | PowerPoint manipulation (.pptx/.potx) | slide deck creation, editing |
| `xlsx` | Spreadsheet manipulation (.xlsx/.csv/.tsv) | data cleaning, formatting, charts |
| `mem0-*` | Memory management (remember, search, tour) | persistent memory across sessions |

## Development Workflow Skills

| Skill | Description | When to Use |
|-------|-------------|-------------|
| `brainstorming` | Explore requirements before implementation | Before ANY creative work |
| `writing-plans` | Create implementation plans from specs | Multi-step tasks before coding |
| `test-driven-development` | TDD cycle (red-green-refactor) | New features, bugfixes |
| `systematic-debugging` | Hypothesis-driven debugging | ANY bug, test failure, unexpected behavior |
| `executing-plans` | Implement plan as executor | Inline plan execution |
| `subagent-driven-development` | Parallel subagent execution | Independent parallel tasks |
| `dispatching-parallel-agents` | Dispatch independent tasks | 2+ independent tasks |
| `using-git-worktrees` | Git worktree isolation | Feature work, parallel dev |
| `verification-before-completion` | Verify before claiming done | Before commit/PR |
| `requesting-code-review` | Request review before merge | Major features, before merge |
| `receiving-code-review` | Handle review feedback rigorously | When receiving feedback |
| `finishing-a-development-branch` | Integrate completed work | All tests pass, ready to merge |

## Skill Creation Skills

| Skill | Description | When to Use |
|-------|-------------|-------------|
| `skill-creator` | Create/modify/measure skills | New skill, edit skill, run evals |
| `writing-skills` | Create/edit/verify skills | Skill development workflow |
| `autoskill` | Detect workflows from screenpipe | Analyze repeated patterns |

## Community Skills (Installable)

```bash
# Install from git
opencode skill install https://github.com/user/my-skill

# List installed
opencode skill list

# Show details
opencode skill show my-skill
```

## Loading Skills

### Automatic (via triggers)
Skills load automatically when trigger phrases detected.

### Manual
```bash
# In session
skill systematic-debugging
skill aeon
skill scanpy
```

### In Agent Config
```jsonc
{
  "skills": {
    "enabled": true,
    "autoLoad": true,
    "directories": [
      "${AGENT_BOOTSTRAP_ROOT}/skills",
      "${HOME}/.config/opencode/skills"
    ]
  }
}
```

## Skill Dependencies

Skills can declare dependencies:
```json
{
  "dependencies": ["analytical-method-validation", "pathway-enrichment"]
}
```
Dependencies load first.

## Creating Custom Skills

See [Skill Development Guide](../guides/skill-development.md)

Template: `skills/skill-template/`