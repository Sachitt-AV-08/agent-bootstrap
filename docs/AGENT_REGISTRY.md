# Agent registry

**163 agents** across 11 domains. Generated from `agents/**/*.yaml`.

| domain | count |
|---|--:|
| `content` | 22 |
| `core` | 8 |
| `debugging` | 20 |
| `docs-dx` | 13 |
| `memory` | 12 |
| `meta` | 6 |
| `orchestration` | 10 |
| `projects` | 18 |
| `research` | 20 |
| `social-media` | 18 |
| `web-scraping` | 16 |

---

## content (22)

- **asset-collector** - Find candidate footage, music, and image assets for a video.
- **certification-creator** - Create certification exams with rubrics and answer keys.
- **color-grader** - Apply consistent color correction and grading across a video.
- **component-catalog-builder** - coder a component catalog with props, states, and usage guidance.
- **design-token-documenter** - Document design tokens with usage rules and constraints.
- **exercise-builder** - coder hands-on exercises with checks and solutions.
- **faq-curator** - Curate frequently asked questions from real support and search data.
- **genesis-video-pipeline** - Render video from a scene DSL using the genesis pipeline.
- **glossary-maintainer** - Maintain a glossary of terms used across the documentation.
- **platform-optimizer** - Optimize a video for YouTube, TikTok, and Instagram Reels delivery specs.
- **quality-control-video** - Inspect rendered video output and report defects.
- **rough-cut-assembler** - Assemble a rough cut from assembled scenes and source footage.
- **scene-composer** - Compose scenes into a structured, editable video timeline.
- **shorts-reformatter** - Reframe long videos into short vertical clips.
- **storyboard-designer** - Design storyboards that map scenes to frames, shots, and timing.
- **subtitle-burner** - Burn or export accurate subtitles and captions.
- **thumbnail-generator** - Generate video thumbnails and cover images.
- **transition-designer** - Design and apply transitions between scenes.
- **usage-guide-writer** - Write task-oriented usage guides for product features.
- **video-script-writer** - Write video scripts with timing, framing, and voiceover beats.
- **voiceover-synthesizer** - Write TTS scripts tuned for synthetic narration.
- **workshop-designer** - Design workshops that produce real participant artifacts.

## core (8)

- **architect** - Designs system structure, module boundaries, and interfaces before implementation starts.
- **coder** - Implements a single approved plan phase, adds tests, and commits at each verified step.
- **incident-commander** - Triages a live incident and delegates debug tasks to other agents without editing code.
- **planner** - Breaks a goal into phased plans with verify gates and rollback points before any code changes.
- **pr-creator** - Opens or updates a pull request from the current branch with a generated summary body.
- **release-manager** - Prepares a version bump, changelog, and deploy gate checks for a release.
- **reviewer** - Reviews a diff for correctness and risk and returns severity-ranked findings.
- **tester** - Writes and runs tests for a feature, touching only test files.

## debugging (20)

- **alert-correlator** - Correlates alerts into incidents and identifies the originating failure.
- **allocation-tracker** - Tracks allocations and ownership lifetimes to find retention and leak sources.
- **bottleneck-identifier** - Identifies performance bottlenecks and quantifies where the time actually goes.
- **config-diff-analyzer** - Compares configuration and environment differences between working and broken states.
- **deploy-timeline-mapper** - Maps deploys, rollouts, and config changes against an incident timeline.
- **distributed-trace-analyzer** - Analyzes distributed traces to find latency sources and failing spans.
- **exception-minimizer** - Minimizes a failure to the smallest reproducing input or code path.
- **flaky-test-isolator** - Isolates flaky tests and identifies the nondeterministic dependency behind each one.
- **flame-graph-reader** - Reads flame graphs and profiles to find where time or allocations actually go.
- **git-bisect-orchestrator** - Orchestrates git bisect runs to find the commit that introduced a failure.
- **lock-contention-finder** - Finds lock contention and produces ranked hypotheses about serialization.
- **log-correlator** - Correlates logs across services by timestamp and trace id to rebuild an incident timeline.
- **memory-leak-hunter** - Hunts memory leaks and produces ranked hypotheses backed by growth evidence.
- **metric-anomaly-detector** - Detects metric anomalies and separates real shifts from noise and seasonality.
- **oncall-assistant** - Assists oncall by ranking the two most likely causes with supporting evidence.
- **postmortem-drafter** - Drafts postmortems as markdown output without editing any repository file.
- **race-condition-finder** - Identifies race conditions and ordering hazards in concurrent code.
- **runbook-executor** - Executes runbook mitigation steps, asking before any command that changes state.
- **stack-trace-decoder** - Decodes stack traces into frames, source locations, and likely failure points.
- **test-failure-minimizer** - Reduces a failing test suite to the smallest failing test and its relevant code.

## docs-dx (13)

- **api-documenter** - Document REST, GraphQL, and library APIs with accurate schemas and examples.
- **blog-post-writer** - Write technical blog posts that explain engineering work clearly.
- **case-study-author** - Write case studies grounded in real customer outcomes.
- **changelog-curator** - Curate changelog entries from commits, pull requests, and releases.
- **comparison-guide-builder** - coder fair comparison guides between products or approaches.
- **decision-record-keeper** - Write and maintain architecture decision records.
- **example-app-builder** - coder runnable example apps that demonstrate project features in realistic ways.
- **launch-announcement-drafter** - Draft launch announcements that match the shipped release.
- **onboarding-engineer** - Produce a first-day path for new contributors to a codebase.
- **readme-generator** - Generate or refresh README files from the real state of a project.
- **seo-content-optimizer** - Optimize technical pages for search while keeping the content accurate.
- **tech-writer** - Write developer documentation for features, libraries, and workflows.
- **tutorial-designer** - Design step-by-step tutorials with runnable exercises and checkpoints.

## memory (12)

- **chromadb-query** - Query a per-project Chroma collection for semantically relevant documents.
- **chromadb-upsert** - Upsert documents and embeddings into a per-project Chroma collection.
- **fact-extractor** - Extract durable facts, decisions, conventions, and constraints from transcripts for user approval before storage.
- **faiss-searcher** - Search a local FAISS index and report matches with their scores and source documents.
- **mem0-context-loader** - Load relevant memories from earlier sessions into context before starting a task.
- **mem0-forget-agent** - Delete outdated or incorrect memories from mem0 after showing the user exactly what will be removed.
- **mem0-search** - Search mem0 for stored decisions, conventions, and context relevant to the current question.
- **mem0-store** - Store a durable fact, decision, or preference into mem0 under an explicit scope.
- **memory-consolidator** - Merge duplicate memories and surface contradictions without deleting anything on its own initiative.
- **qdrant-filter-query** - Run filtered vector queries in Qdrant and report the payload filters used.
- **qdrant-upsert** - Upsert points and vectors into a per-project Qdrant collection with explicit payloads.
- **sqlite-vec-indexer** - coder and refresh a local SQLite vector index of documents for fast retrieval.

## meta (6)

- **conflict-resolver** - Compares competing proposals and recommends one with explicit reasons.
- **fleet-commander** - Plans and launches a fleet of subagents, assigning each one an isolated worktree.
- **knowledge-synthesizer** - Merges session findings into durable notes that outlive the current session.
- **priority-negotiator** - Orders competing tasks by urgency and impact and resolves who works on what first.
- **result-aggregator** - Collects agent findings, removes duplicates, and emits one markdown report grouped by severity.
- **retrospective-facilitator** - Runs a structured retrospective on how a piece of work went and what to change.

## orchestration (10)

- **agent-lifecycle** - Manages the spawn to run to collect to cleanup state machine for each agent.
- **consensus-builder** - Turns N agent opinions into one consensus recommendation while preserving dissent.
- **cost-tracker** - Estimates token usage and cost per agent run from small-model versus main-model routing.
- **fleet-collector** - Gathers the diffs from every fleet worktree into one consolidated report.
- **parallel-executor** - Runs independent plan phases concurrently while keeping dependent phases strictly sequential.
- **quality-gate** - Defines pass or fail criteria for each phase and blocks promotion when a gate fails.
- **result-dedupe** - Detects exact and near-duplicate findings across agent reports before they are aggregated.
- **session-tracker** - Maintains the mapping from task to worktree to agent sessionID for the whole run.
- **subagent-spawner** - Chooses the right agent type for a task and spawns it with the arguments it needs.
- **worktree-manager** - Creates, lists, and prunes git worktrees for parallel agents under .lane/trees/.

## projects (18)

- **audio-mixer** - Mix and master Genesis audio tracks with ffmpeg while holding loudness targets and avoiding clipping.
- **auth-persist** - Keep authenticated browser sessions alive across agent runs without ever exposing credentials.
- **browser-session-manager** - Attach the orvima agent session to the user's already-running Chrome or Edge instead of launching a clean profile.
- **contact-manager** - Resolve WhatsApp contact names to chat ids and report ambiguous matches instead of guessing.
- **extension-bridge** - Design read-only CDP extension integration for orvima without touching the running browser.
- **genesis-subtitle-burner** - Burn subtitle tracks into Genesis video output with safe-area margins and known fonts.
- **group-admin** - Prepare WhatsApp group send, reaction, and member-removal actions that each require explicit per-action approval.
- **mcp-tool-expander** - Map new orvima browse_* MCP tools into existing agent workflows and keep the tool reference accurate.
- **media-handler** - Download and inspect WhatsApp attachments only when the user explicitly asks for a specific file.
- **message-parser** - Parse WhatsApp messages into structured records with chat, sender, timestamp, text, and attachments.
- **playwright-optimizer** - Tune orvima browse actions for speed and reliability using repeatable benchmark runs.
- **quality-optimizer** - Inspect rendered Genesis outputs with ffprobe and report bitrate, resolution, duration, and defects.
- **render-farm** - Distribute Genesis renders across workers with a memory-aware parallelism cap.
- **scheduler-manager** - Schedule WhatsApp messages with parley, showing the exact recipient, text, and time before anything is queued.
- **thumbnail-gen** - Generate thumbnail image candidates from Genesis scenes using ffmpeg without touching the originals.
- **video-pipeline** - Compose and render DSL video scenes through the Genesis engine and report per-scene timing.
- **viewport-streamer** - Capture viewport screenshots for visual verification of orvima browser automation.
- **whatsapp-session** - Attach to the running WhatsApp Desktop session and confirm account identity before any messaging action.

## research (20)

- **benchmark-aggregator** - Aggregates published benchmark numbers into one comparable table without inventing values.
- **citation-mapper** - Builds citation graphs and flags every citation it cannot verify.
- **competitor-monitor** - Runs scheduled monitoring of competitor releases, pricing, and positioning changes.
- **dataset-finder** - Finds datasets for a task and documents license, format, and access constraints.
- **dependency-grapher** - Maps dependency graphs, version constraints, and supply-chain exposure.
- **feature-matrix-builder** - Builds feature matrices comparing competitor capabilities across dimensions.
- **gap-analyzer** - Identifies what prior work does not cover, leaves thin, or contradicts.
- **methodology-comparer** - Compares methodologies, baselines, and metrics across works to expose tradeoffs.
- **paper-fetcher** - Fetches academic papers and records verifiable identifiers for every source it uses.
- **patent-landscape-mapper** - Maps the patent landscape around a technology area and flags claim overlap risk.
- **positioning-mapper** - Maps how products position themselves against each other on audience and differentiators.
- **pricing-analyzer** - Compares competitor pricing, plans, and unit economics with a cited page and date per price.
- **prior-art-searcher** - Searches for prior art and earlier implementations of a proposed idea.
- **reproducibility-checker** - Checks published claims for reproducibility and states exactly what it could and could not reproduce.
- **rfc-analyzer** - Analyzes RFCs for design decisions, dependencies, and implementation impact.
- **semantic-scholar-miner** - Mines the Semantic Scholar graph for related work, influence, and citation context.
- **source-code-archaeologist** - Reconstructs why code looks the way it does using history and diffs.
- **spec-reader** - Reads specifications and standards and extracts enforceable requirements.
- **swot-synthesizer** - Synthesizes strengths, weaknesses, opportunities, and threats from gathered evidence.
- **trend-spotter** - Detects emerging trends and shifts in a technical landscape with timestamps and sources.

## social-media (18)

- **asset-library** - Maintain an organized library of reusable social media assets.
- **campaign-manager** - Coordinate a social campaign by delegating research and drafting to subagents.
- **cross-platform-scheduler** - Coordinate one campaign's publishing across platforms.
- **engagement-analyzer** - Analyze social engagement data for patterns and next actions.
- **influencer-finder** - Find and assess influencers against defined campaign criteria.
- **instagram-competitor-tracker** - Track how competing Instagram accounts actually post.
- **instagram-dm-automator** - Draft Instagram direct messages and comment replies for approval.
- **instagram-hashtag-researcher** - Research Instagram hashtags with current, account-specific evidence.
- **instagram-post-publisher** - Draft Instagram feed posts for approval before anything is published.
- **instagram-reel-uploader** - Prepare Instagram Reels for upload, with approval before posting.
- **instagram-story-scheduler** - Draft Instagram story sequences and their schedule for approval.
- **linkedin-analytics-reader** - Read and interpret LinkedIn post and page analytics.
- **linkedin-connection-manager** - Review and triage LinkedIn connection requests for approval.
- **linkedin-dm-automator** - Draft LinkedIn direct messages for approval before sending.
- **linkedin-post-publisher** - Draft LinkedIn posts for approval before anything is published.
- **linkedin-profile-enricher** - Research a LinkedIn profile and draft optimization suggestions.
- **sentiment-tracker** - Track public sentiment around a brand, product, or topic.
- **social-content-calendar** - Plan a social content calendar across channels.

## web-scraping (16)

- **article-extractor** - Strip boilerplate from article pages and return clean main-body text using trafilatura or newspaper3k.
- **data-validator** - Validate scraped records against a schema and surface every invalid row instead of dropping it.
- **dynamic-scraper** - Scrape JavaScript-rendered pages through the orvima MCP browse tools when plain HTTP returns a shell page.
- **newspaper-parser** - Parse newspaper-style archives and RSS feeds into structured article records.
- **rate-limiter** - Enforce per-domain concurrency and delay budgets so scraping stays polite and inside limits.
- **robots-checker** - Verify whether robots.txt permits a target path before any scraping begins.
- **scrapy-crawler** - Run a bounded Scrapy crawl over an allowed site with enforced delays and concurrency caps.
- **sitemap-discoverer** - Discover crawlable URLs from sitemaps, robots.txt entries, and feed indexes.
- **static-scraper** - Fetch and parse plain HTML pages into structured records with python -m scrape.static.
- **youtube-channel-auditor** - Audit a YouTube channel's catalogue, upload cadence, and metadata consistency.
- **youtube-comment-analyzer** - Analyze the comment threads of a YouTube video or channel for themes and sentiment.
- **youtube-playlist-archiver** - Inventory a YouTube playlist and archive its metadata, ordering, and subtitle availability.
- **youtube-shorts-analyzer** - Analyze YouTube Shorts for format patterns, hooks, and duration distributions.
- **youtube-transcript-fetcher** - Fetch and clean a YouTube transcript for a given video, playlist, or channel.
- **youtube-trend-spotter** - Spot emerging topics and velocity shifts across a set of YouTube videos or channels.
- **yt-dlp-extractor** - Extract YouTube video metadata, format listings, and subtitles with yt-dlp when asked.
