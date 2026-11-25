# QoreLease Frontend Agent Playbook: Taste Skill + Uibrik

**Purpose:** A practical instruction and reusable agent prompt for designing QoreLease's public website and authenticated application using the current Taste Skill and Uibrik.  
**This document is a design/agent handoff, not authorization to start frontend coding.** The owner may provide additional visual references and approve the overall direction first. The agent is expected to exercise design judgment and is not constrained to reproduce the example layouts in this pack.

---

## 1. Sources and versions

### Taste Skill

- Repository: <https://github.com/Leonxlnx/taste-skill>
- Current skill install name: `design-taste-frontend`
- Current main `SKILL.md` identifies itself as tasteskill 2.5; the repository changelog identifies the current release as 2.5.1.
- Install command:

```bash
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

The skill needs Node 22+ and Chrome, Edge or Chromium for its browser checks. Its current main workflow uses page-kind classification, a copy-first brief, screen planning, layout/palette dealers, motion assets, browser checks and a finish gate. Do not substitute the archived `design-taste-frontend-v1` or `design-taste-frontend-v2-experimental` skill unless the owner explicitly asks for one.

### Uibrik

- Website: <https://uibrik.com/>
- Introduction: <https://uibrik.com/docs/introduction>
- Installation: <https://uibrik.com/docs/installation>
- Agent playbook: <https://uibrik.com/docs/agents>
- MCP guide: <https://uibrik.com/docs/mcp>
- Skill file: <https://uibrik.com/skill.md>
- Component map: <https://uibrik.com/llms.txt>
- MCP endpoint: `https://uibrik.com/mcp`

Uibrik is not a conventional npm component package. The shadcn CLI installs editable source files into the project (normally `components/uibrik/<slug>/`) and adds the component's npm dependencies. It is based on React 19, Tailwind CSS v4, shadcn setup and Motion. It works with Next.js and Vite when the project's setup meets those requirements.

## 2. Required Uibrik workflow

Follow these five steps in order:

1. **Search by job, not by component name.** Examples: “provider avatars that fan out on hover,” “ranking list whose rows animate when sorted,” “status pill that transitions between states,” “event feed where new events insert at the top.” Use MCP `search_components` or the catalogue in `llms.txt`.
2. **Read the component's Markdown twin.** `https://uibrik.com/components/<slug>.md` describes access level, files written, dependencies, requirements, install command, render snippet, props, integration notes and ground rules.
3. **Install from the registry.** Use the component's own install command, normally `npx shadcn@latest add https://uibrik.com/r/<slug>.json`. Do not manually rewrite a component that is already available.
4. **Adapt the installed source in place.** Prefer passing real QoreLease data through the documented props. If custom behavior is needed, edit the source under `components/uibrik/` and preserve attribution/license notices.
5. **Inspect the result.** Check dark and light themes and phone width. Validate accessibility, keyboard support and reduced-motion behavior.

MCP server details:
- Remote Streamable HTTP endpoint: `https://uibrik.com/mcp`.
- Tools documented by Uibrik: `search_components`, `get_component`, `list_categories`, `get_install_instructions`.
- No account or key is needed for free components. Pro source requires an appropriately licensed key; it must be stored in the MCP configuration as a secret header, never in chat or committed config.

**Do not assume the app is compatible.** First inspect its package.json, React version, Tailwind version, shadcn `components.json`, path aliases and existing design tokens. If the app is not on React 19 + Tailwind v4 + shadcn, report the compatibility gap and propose a minimal, owner-approved migration plan. Do not silently migrate the whole app just to install one component.

## 3. Taste Skill workflow for QoreLease

The current Taste Skill classifies QoreLease as `page type: software` and `site-kind: software` (SaaS / AI / developer tool / fintech). Use the current skill's actual files and scripts, not an old copy-pasted recipe. **Apply its full art-direction, big-scene and finish-gate workflow to the public marketing site. Do not blindly impose the marketing-site scene/moment system on authenticated dashboards or dense application screens; use the QoreLease product system and Uibrik for those task-oriented surfaces.**

Before first page:
1. Read `copy.md`, `copy-voice.md`, `system.md`, `layout-v4.md` and `sections.md` completely.
2. Read the product spec documents in this package.
3. Inspect the current QoreLease README, architecture, interfaces, state machines, and actual Phase 1 code. Do not invent capabilities.
4. Write a one-line design read and a copy/voice fact sheet.
5. Plan the entire public landing page as screens: section id, idea, visual, visual type, screen count, action and motion purpose.
6. Use the Taste Skill layout/palette dealers and record their outputs and why the palette fits a technical AI procurement product. The current skill says to deal rather than casually choose and to avoid a generic default look.
7. Arm the Taste Skill finish gate before building the page. Use the command form appropriate for the existing framework/dev server.
8. Keep the public website and authenticated product app as distinct design contexts sharing one design system. Do not let a landing-page hero layout dictate dashboard density.
9. Read `docs/ui-ux/05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md`. Plan one deliberate pinned/sticky scroll scene on the public landing page only if the Taste Skill scene dealer finds a suitable scene and the actual product UI meets its requirements. Do not add generic scroll reveals across every section.

For an existing React app, preserve its framework and application architecture. The Taste Skill's current `SKILL.md` explains how to adapt its assets and system to an existing stack. Do not replace the smart-contract/provider architecture or introduce a new backend while doing UX work.

## 4. Proposed component discovery shortlist

The agent should search the live catalogue first and use these queries as starting points:

- “Provider avatars on offer cards, fan out on hover, accessible labels.”
- “Status badge for reservation lifecycle, transition color/icon/label.”
- “Ranked provider offer list with sortable metrics.”
- “Event feed for reservation, workload, evidence and settlement events.”
- “Split bar showing available, reserved and consumed capacity.”
- “Gauge for latency target or capacity utilization with keyboard input.”
- “Animated text entrance for a short hero headline.”
- “Animated comparison of three competing service-provider offers.”
- “Scroll-driven pinned product story: same stage, changing interface chapters, native browser scroll, accessible static fallback.”

Likely current catalogue candidates include `avatar-stack`, `status-badge`, `bar-list`, `event-feed`, `split-bar`, and `gauge-dial` (reported as free in the current catalogue). `benchmark-race`, `live-line`, and complete dashboard blocks are marked Pro in the current catalogue. Re-check the live entry; access/pricing may change.

Do not install a component because its name sounds right. Match the actual UX requirement and read the current `.md` page. Avoid using large Pro app-screen blocks as a substitute for QoreLease information architecture.

## 5. Recommended frontend build order after design approval

1. **Design tokens and app shell:** type, color, spacing, radius, buttons, forms, navigation, status language, theme and responsive containers.
2. **Public landing page:** hero, provider sprint, buyer/provider value, how it works, two-runtime diagram, transparent limitations, final CTA.
3. **Buyer core journey:** create request → compare offers → review terms and total escrow → wallet confirmation → reservation detail → delivery/evidence → settlement receipt.
4. **Provider core journey:** onboarding → service profile → bond/eligibility → capacity slots → reservation inbox → execution → evidence → payout.
5. **Network/transaction state surfaces:** wrong network, authorization window, bridge error, pending/unknown transaction, Native rejection, evidence failure and refund.
6. **Responsive and accessibility pass:** desktop/tablet/mobile, keyboard-only, reduced-motion, contrast and empty/error states.
7. **Browser QA and finish gate:** Taste Skill copy/consistency/layout/perf/gate reports and Uibrik component checks.

## 6. Reusable prompt for the frontend coding agent

Paste this prompt only after the owner has approved the visual direction and is ready to authorize frontend implementation.

---

### Agent task: design and implement QoreLease frontend using Taste Skill + Uibrik

You are working in the existing QoreLease repository. Your task is the frontend experience only. Do not modify Rust contracts, Solidity contracts, provider adapter protocol behavior, token economics, or deployment configuration unless the owner explicitly authorizes a separate task.

#### Start by understanding the product

Read:
- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/INTERFACES.md`
- `docs/STATE_MACHINES.md`
- `docs/THREAT_MODEL.md`
- `docs/TEST_PLAN.md`
- `docs/ui-ux/01_PRODUCT_EXPERIENCE_SPEC.md`
- `docs/ui-ux/02_SCREEN_MAP_AND_USER_FLOWS.md`
- `docs/ui-ux/03_VISUAL_LANGUAGE_AND_MOTION.md`
- `docs/ui-ux/04_AGENT_TOOLING_AND_HANDOFF.md`
- `docs/ui-ux/05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md`

Inspect the current frontend stack before installing anything. Confirm React, Next.js/Vite, Tailwind, shadcn, router, state management, data clients and existing theme. Preserve existing working stack choices.

#### Use Taste Skill

Load current `design-taste-frontend` from the official repository. Verify the installed skill's version and read its current `SKILL.md`, plus the required references `copy.md`, `copy-voice.md`, `system.md`, `layout-v4.md`, and `sections.md`.

Treat QoreLease as a software / AI / fintech / developer-tool product. Follow the skill's copy-first, screen-plan, layout/palette deal, motion-asset, real-browser QA and finish-gate workflow. Do not apply an archived v1/v2-experimental guide by mistake.

#### Use Uibrik

Connect the Uibrik MCP server at `https://uibrik.com/mcp` if the coding environment supports remote Streamable HTTP MCP. Otherwise use `https://uibrik.com/llms.txt` and the Markdown component pages.

For every selected component:
1. Search by the interaction job.
2. Read its current Markdown spec sheet.
3. Check Free/Pro status and dependencies.
4. Install with the documented shadcn registry command.
5. Adapt source in `components/uibrik/`.
6. Check light/dark and mobile.

Do not use Pro source without owner approval/license. Do not reproduce a Pro component from its preview.

#### Design constraints

- Build a technically credible, premium procurement product, not a generic crypto dashboard.
- Explore the interactive “Provider Sprint” as one possible landing-page concept: three stylized provider archetypes respond to one sample AI-service request. It is illustrative demo data unless backed by a live provider/offers API.
- This is a creative seed, not a mandatory design. You may replace the characters, metaphor, composition or entire hero concept if a stronger idea better explains competitive capacity procurement. Show the owner three materially different directions and recommend one.
- Use the product's actual UI as a live HTML visual, not a fake dashboard screenshot.
- Use restrained motion for feedback, selection, state changes and the provider comparison story. Provide pause/replay for loops and reduced-motion alternatives.
- Avoid AI-purple gradient defaults, blanket glassmorphism, random neon, three identical feature cards, tilting cards and motion without meaning.
- Keep visual hierarchy, copy, numbers, states, and affordances accessible and responsive.

#### Scroll storytelling and motion direction

Read `docs/ui-ux/05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md` in full. The public landing page should explore one signature scroll-driven scene in which a stable stage/background remains anchored while the QoreLease product UI and active narrative chapter change with native vertical scroll. This must be a dedicated section using a suitable scene selected through the current Taste Skill workflow. The `product-assembles-into-its-action` scene is a promising candidate, not a mandate; inspect the current dealer output, scene metadata and asset needs before choosing.

Do not scroll-animate every section or card. Keep the rest of the landing page calm. Do not hijack scroll, run custom per-frame React state listeners, or make content invisible until a scroll animation fires. Use the Taste Skill's own scene runtime for the pinned scene, and use Motion/CSS/Uibrik for local UI interactions without animating the same element from multiple systems.

On authenticated buyer/provider pages, prioritise task completion. Use short, state-driven transitions for offer selection, transaction steps, capacity changes, evidence and settlement. Avoid cinematic pinned scroll scenes in operational workflows.

#### Creative autonomy

The examples in this design pack are inspiration, not a rigid UI specification. You are expected to contribute original design thinking. Explore at least three materially different art directions (not just palette changes), including the option to replace or remove the suggested provider characters if a better metaphor exists. Recommend one based on product clarity, originality, trust, performance and feasibility.

You may invent stronger compositions, visual metaphors, characters, custom SVG/CSS/Canvas details, interactions, motion choreography, layout rhythms and Uibrik component combinations than the examples here. Do not ask for approval on every small visual choice. Ask only before paid Pro licenses, material brand/identity decisions, changed product claims or user journeys, or new dependencies that affect the app architecture. Document substantial deviations and why they improve the product. Product truth, accessibility, reduced motion, mobile usability, performance and licenses remain hard constraints.

Create `docs/ui-ux/DESIGN_EXPLORATIONS.md` with the three distinct concepts, a recommendation, selected Taste Skill deals, Uibrik candidates, motion/scroll plan and trade-offs. After owner approval, write `DESIGN_DECISIONS.md` and implement the approved direction.

#### Product-truth constraints

The Phase 1 implementation currently supports request creation and acceptance/reservation flows. It does not yet contain a full on-chain auction/bidding engine, sealed bids or on-chain auto-winner selection. Treat provider discovery/offer collection as an off-chain service until that functionality exists. Do not label a quote comparison as an on-chain auction.

The Phase 1 provider adapter uses local/in-memory services and a local OpenAI-compatible mock. Its monitor digests are not real signatures or quorum. Do not present simulated evidence as independently verified.

Diana staking query, mapped sender identity, bridge response encoding, actual atomic rollback, fUSD deployment configuration and governance upload/allowlisting remain unverified. Show honest Testnet / Demo / Not connected / Unverified states. Never fabricate contract addresses, token addresses, provider metrics, transactions or live status.

#### Delivery expectations

- Implement the approved screens and flows, not just a static landing page.
- Use real app state and actual backend/client contracts when connected. For unimplemented endpoints, use an explicitly labelled demo state and isolate mock data.
- Provide loading, empty, validation, success, pending, unknown-outcome and failure states.
- Keep all money, reservation and evidence values traceable to a source and timestamp.
- Add tests for critical form validation and state mapping.
- Check desktop (1440), tablet (768/820), mobile (390) and overflow at 320.
- Respect keyboard, focus, labels, contrast and reduced motion.
- Run Taste Skill copy lint, consistency/layout/performance checks and finish gate. Report the gate result exactly; do not hide FAILs or invent a PASS.
- Run the actual app's existing tests and build.
- Report files changed, components installed, Pro components requested (if any), browser screenshots, test results, gate output, and all unimplemented/live-Diana blockers.

Do not alter contracts or attempt any blockchain transaction as part of frontend implementation.

---

## 7. Deliverables expected from the frontend agent

- `docs/ui-ux/DESIGN_DECISIONS.md` with selected layout/palette/type and rationale.
- A page/route map that matches the product spec.
- Implemented landing page and buyer/provider core workflows.
- Component inventory showing Uibrik source component slugs, versions/access level and where used.
- Motion inventory with trigger, purpose, duration, implementation owner, reduced-motion behavior, skip/pause behavior and fallback.
- `docs/ui-ux/DESIGN_EXPLORATIONS.md` with three distinctly different creative directions and a recommendation.
- A documented pinned-scene plan and responsive/reduced-motion still state.
- Responsive screenshots at 1440, 1024, 768 and 390 (plus 320 overflow check).
- Taste Skill copy/layout/perf/finish-gate reports.
- Tests and build output.
- A list of UI states that still depend on unverified Diana integration.

## 8. Sources checked for this handoff

### Taste Skill
- Main repository: <https://github.com/Leonxlnx/taste-skill>
- Current skill file: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/SKILL.md>
- Changelog: <https://github.com/Leonxlnx/taste-skill/blob/main/CHANGELOG.md>

### Uibrik
- Home: <https://uibrik.com/>
- Introduction: <https://uibrik.com/docs/introduction>
- Installation: <https://uibrik.com/docs/installation>
- Agents: <https://uibrik.com/docs/agents>
- MCP: <https://uibrik.com/docs/mcp>
- Agent skill: <https://uibrik.com/skill.md>
- Catalogue: <https://uibrik.com/llms.txt>

### QoreLease implementation reference
- Repository: <https://github.com/hari-ramsss/chronolease>
- Architecture: <https://raw.githubusercontent.com/hari-ramsss/chronolease/main/docs/ARCHITECTURE.md>
- Interfaces: <https://raw.githubusercontent.com/hari-ramsss/chronolease/main/docs/INTERFACES.md>
- State machines: <https://raw.githubusercontent.com/hari-ramsss/chronolease/main/docs/STATE_MACHINES.md>
