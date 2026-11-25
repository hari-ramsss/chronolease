# QoreLease Visual Language, Character Direction, and Motion System

**Purpose:** Establish the art direction and motion principles for QoreLease before frontend implementation.  
**Primary references:** Current Taste Skill 2.5.1 main skill and Uibrik's React component library / Motion-based interactions.

---

## 1. Design read

**Reading this as:** a software / fintech / AI procurement application for technical buyers and API/inference providers, with a confident, engineered, competitive marketplace language. It should feel like a premium developer product with a human-readable procurement experience, not a playful consumer game and not generic Web3 dashboard chrome.

QoreLease is a software product. The current Taste Skill classifies SaaS, AI, developer tools and fintech as `software` page type / `software` site-kind. Its current guidance allows a technical visual treatment, real product UI, compact diagrams, real tool icons, and one carefully chosen effect plus one or two page moments. <https://github.com/Leonxlnx/taste-skill/blob/main/skills/taste-skill/SKILL.md>

## 2. Taste Skill version and workflow interpretation

Use the current main-branch skill install name:

```bash
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

The current main `SKILL.md` identifies itself as **tasteskill 2.5** (the repository changelog identifies the release as 2.5.1). It is the version to follow for this project. Do not accidentally use the archived `taste-skill-v1` or `taste-skill-v2-experimental` instructions as if they were the current main skill. The older experimental file is preserved separately and has a different, dial-first workflow.

The current workflow is not simply “pick a layout and add GSAP.” It requires the agent to:
1. Classify the business/page kind.
2. Read the product brief and identify the thing sold, audience, main transaction/action and real materials.
3. Write copy before layout.
4. Plan the page as screens, each section's idea, visual and motion purpose.
5. Use the skill's layout and palette dealers rather than choosing a generic template by habit.
6. Build with the skill's system, motion and visual assets.
7. Run copy, consistency, layout, performance and finish-gate checks in a real browser.

Before first page work, the current skill specifically calls for reading `copy.md`, `copy-voice.md`, `system.md`, `layout-v4.md` and `sections.md` in full. It also requires the page plan and the finish gate. See `04_AGENT_TOOLING_AND_HANDOFF.md` for the implementation procedure.

## 3. Visual direction

### 3.1 Desired character

- Precise, competitive, intelligent, assured.
- Technical details presented with calm hierarchy.
- Slightly kinetic, with movement that explains matching, ranking, reservation and settlement.
- Premium and serious enough for procurement / infrastructure teams.
- Expressive enough to make “providers competing for a job” memorable.

### 3.2 Avoid

- Generic AI-purple gradients and a centered hero over a dark mesh.
- Glassmorphism on every panel.
- Three identical feature cards as the entire homepage.
- Neon cyberpunk overload or a trading-terminal wall of numbers.
- Cartoon characters that make a financial/procurement product feel like a children's game.
- Continuous motion on every card, number, background and cursor.
- Fake “LIVE” metrics, fake customer logos, fake provider history, or fake successful transactions.

### 3.3 Palette and type

The exact palette and font pairing should be selected by the current Taste Skill's software/fintech palette and type-dealing workflow, then reviewed by the owner. The agent must record which palette and type pairing was dealt and why it suits QoreLease. Do not force an unrelated template palette.

Directional guardrails:
- Prefer a controlled, high-contrast technical palette over generic AI purple.
- Use one primary accent for key actions and one clear semantic status palette for success, warning and failure.
- Keep surfaces quiet; borders, spacing and typography should carry hierarchy rather than glow on every card.
- Use tabular/monospaced numerals for IDs, token amounts, latency, throughput and hashes where they improve scanability. Use a highly legible text face for prose.
- Fintech / developer-tool interfaces use a sharper radius language; reserve softer corners for avatars and compact interactive controls.
- Support light and dark modes if the app theme is designed for both; do not assume all dashboards must be permanently dark.

### 3.4 Layout

- Public landing page: varied but coherent editorial sections, one hero message, one primary action, one real product visual, and one or two composed moments.
- App workspace: denser than the marketing site, but not a cockpit. Use a stable grid, fixed content edges, clear section headings and an intentional hierarchy between state, money and service metrics.
- Use the actual QoreLease UI as the product visual. Taste Skill explicitly expects software pages to show the product's own UI as live HTML rather than a fake decorative dashboard.
- Keep every content section to a coherent viewport rhythm. Avoid multiple unrelated headings competing on the same screen.

---

## 4. Hero character concept: “The Provider Sprint”

The owner's concept of characters competing for an AI service request is strong if executed as a restrained product illustration.

### Character system

Create three original provider-agent characters with distinct silhouettes and value propositions. They are visual metaphors for provider profiles, not autonomous agents with independent on-chain identities.

1. **Swift** — latency-first provider archetype. Narrow, fast silhouette; visual language of speed / response.
2. **Atlas** — capacity-first provider archetype. Broad, stable silhouette; visual language of throughput / concurrency.
3. **Lean** — cost-efficient provider archetype. Compact, efficient silhouette; visual language of price / resource efficiency.

Names are placeholders for the visual concept. The product owner should approve final names and character art. Do not imply these characters are actual provider brands or live agents.

### Scene composition

- A buyer request is presented as a central job card.
- Three characters approach on separate lanes, each carrying an offer tile.
- Each offer tile reveals the same comparable attributes: price, units, latency target / observed latency, success rate / measurement window, and capacity window.
- The selection is based on the buyer's selected priorities. For example, an explicitly selected “lowest latency” preference highlights the relevant offer; “lowest total cost” highlights another.
- The selected offer moves into a reservation review state. It does **not** jump straight to a green “On-chain reserved” check.
- The non-selected provider characters remain visible as alternatives rather than disappearing as if they were rejected by an invisible auction contract.

### Truthful demo treatment

If the scene uses fabricated sample data:
- Label it `Interactive example` or `Demo data`.
- Provide a replay / pause control.
- Do not use a live-chain badge.
- Do not use a real provider name, real SLA claim, or transaction hash.
- Use wording such as `Offer selected in this demo`, not `Auction settled` or `Native capacity reserved`.

### Visual implementation direction

The characters can be bespoke SVG / CSS / generated illustration assets or a small canvas scene. They should not look like generic bot emoji. Keep their silhouettes recognisable when reduced to a small avatar. Use a small set of shape primitives, one consistent stroke/fill language, accessible labels and a still-image fallback.

The Taste Skill's one-effect rule for technical pages should be respected. The character sprint and animated product visual should be composed as one coherent hero moment rather than adding multiple independent WebGL scenes.

---

## 5. Motion principles

Motion must answer one of four questions:
- What is moving into focus?
- What changed because the user acted?
- What state has advanced?
- What relationship or flow is being explained?

If an animation does not answer one of these, remove it. Follow the current Taste Skill 2.5.1 motion/effect budget rather than inventing a second motion system: every page gets the one-time hero entrance, the dealt moment(s), and working hover/press/focus feedback. A software page may additionally use the skill-approved timed loop(s), count, pulsing diagram cards and at most one big scene/effect as the live dealer and finish gate permit. The exact number and placement of beats must come from the current skill scripts and metadata, not from an arbitrary interpretation of this document.

### 5.1 Motion tiers

**Tier 1: Essential micro-interactions**
- Button hover / press feedback.
- Offer card selection.
- Status badge transition.
- Filter and sort result movement.
- Copy-hash confirmation.
- Input validation / error focus.

**Tier 2: Product-story motion**
- Hero provider sprint.
- Offer comparison bars sorting into a selected rank.
- Request card transforming into a confirmed reservation card after a real success response.
- Native/EVM flow diagram pulsing through the actual sequence.
- Job timeline advancing one state at a time.

**Tier 3: Optional analytical motion**
- Latency chart updates.
- Capacity allocation bars changing after reservation.
- Collateral available/locked balance animation.

Do not make every dashboard chart animate continuously. Data changes should animate once when new data arrives, not loop for decoration.

### 5.2 Signature motions

| Motion | Trigger | Purpose | Implementation note |
|---|---|---|---|
| Provider sprint | Hero enters viewport / Replay | Show competitive offer discovery | 3.5-4s example loop, pause button, reduced-motion static state |
| Offer selection | Buyer selects an offer | Show the selected provider and terms | Shared-layout transition; preserve card identity and position |
| Reservation progress | Wallet / transaction event | Explain EVM → Native → confirmation | Progress only advances when the actual event/receipt arrives |
| Capacity bar | Native state changes | Show reserved vs. available units | Animate only on confirmed state update |
| Bond split | Reservation / finalization event | Explain available vs. locked collateral | Use number change and split-bar movement; show source and timestamp |
| Evidence reveal | Report submitted / accepted | Make the evidence lifecycle understandable | Reveal hashes and monitor identity progressively; never forge a signature visual |
| Settlement receipt | Settlement receipt confirmed | Give closure and transaction traceability | Receipt panel unfolds after successful state is confirmed |

### 5.3 Timing and easing

- Micro-interactions: 120-220ms.
- Component state change: 180-320ms.
- Section / hero entrance: 450-900ms, choreographed once.
- Hero competition demo: around 3.5-4 seconds per complete loop.
- Avoid overshoot and rubbery motion for money, reservation and security states. Use a crisp ease-out / restrained spring.
- No perpetual motion on operational data. Pause any loop longer than five seconds and provide an explicit pause control.

### 5.4 Technical and accessibility requirements

- Respect `prefers-reduced-motion`; use a static state with all content visible.
- Provide pause/replay for the hero demo.
- Do not communicate a state only through movement, sound, color or a character animation.
- Use transform and opacity for the majority of animation; avoid animating layout dimensions at high frequency.
- Keep keyboard focus visible; motion must not shift focus or break reading order.
- On small screens, simplify or replace the hero race with stacked provider lanes and a static comparison state.
- Do not use scroll hijacking, custom `window.scrollY` state loops, or arbitrary `requestAnimationFrame` loops that drive React state.
- For ordinary interface interactions use the existing UI motion layer / Motion primitives or a selected Uibrik component. For the one intentional public-page pinned scene, use the current Taste Skill scene implementation and its documented scroll runtime. Do not let two motion systems animate the same properties on the same element.

---


### 5.5 Scroll-driven storytelling: one anchored stage, changing product UI

The previous motion plan named a hero provider sprint and product-state transitions, but did not specify the scroll composition clearly enough. This is now an explicit design requirement for the public landing page.

The visual should work like this:
- A dedicated section holds a stage in place while native page scroll advances through a small number of chapters.
- The stage's background, framing and visual environment stay consistent.
- Foreground QoreLease interface elements change: request fields appear, provider offers compare, the chosen reservation/escrow state is assembled, and delivery/settlement details become visible.
- A narrative rail highlights the active chapter. The viewer always knows where they are and what the state means.
- The scene resolves into one action/receipt state, then releases naturally into the next page section.

**Taste Skill fit:** QoreLease is a software/AI product. The current Taste Skill supports at most one big scene on a technical page when the brief has the required real assets. `product-assembles-into-its-action` is an especially relevant candidate because it builds the product's own screen through 4–6 steps, then folds it into its action. The agent must use the current dealer and actual scene metadata rather than selecting it by preference alone. See the new `05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md`.

**Do not:** pin the whole website, trap scrolling, animate every section on entry, parallax body text, or put scroll-linked motion into operational app tables/forms. The scroll scene is one composed section; the rest of the landing page and all task-oriented app screens remain readable and calm.

### 5.6 Creative direction is open, not locked

The names Swift, Atlas and Lean and the “Provider Sprint” are concept seeds. The agent may keep them, redesign them, replace them with a stronger metaphor, or remove character-led visuals entirely. It should explore at least three genuinely different design directions and make a reasoned recommendation.

The owner is approving product truth and major direction—not every CSS, type scale, component or easing decision. Give the agent room to create original compositions, custom motion, visual metaphors and interactions beyond the examples in this pack. It must explain significant deviations and preserve product truth, accessibility, responsiveness, performance, licensing and the current Taste Skill/Uibrik rules.

## 6. Uibrik components to investigate first

Use Uibrik's live MCP catalogue to search by interaction job. These are promising candidates identified in the current public catalogue; the agent must confirm the current spec sheet, free/Pro status, dependencies and props before installation.

| Component | Current catalogue indication | QoreLease use | Guardrail |
|---|---|---|---|
| Avatar Stack | Free | Provider / monitor avatars on offer cards or activity | Do not use as a fake live participant count |
| Status Badge | Free | Reservation, evidence and provider status transitions | Status data must come from a real state source |
| Gauge Dial | Free | Buyer latency threshold / provider utilization control | Keep exact numeric input available alongside it |
| Bar List | Free | Ranked offer comparison | Explain the ranking metric; no opaque “AI score” |
| Event Feed | Free | Reservation, execution, evidence and settlement events | Only show events that actually occurred |
| Split Bar | Free | Capacity: reserved / consumed / available; bond: locked / available | Use chain-derived values after connection |
| Benchmark Race | Pro | A landing-page comparison moment for provider performance | Pro source requires a license; never recreate it from a preview |
| Live Line | Pro | Streaming latency / throughput on a provider dashboard | Only when real telemetry is available and a Pro license is approved |
| Status Dashboard | Pro | Reference only for a future monitoring view | Avoid importing a whole dashboard before information architecture is approved |

The list is a shortlist, not a mandate. If a component is Pro, the agent must tell the owner, provide its preview and pricing link, and suggest the closest free alternative. Never recreate Pro source from public previews or props.

---

## 7. Visual QA expectations

The current Taste Skill's QA process expects:
- Browser renders at 1440, 1024, 768 and 390 widths (plus narrow 320 overflow check).
- Clear first screen with product category, buyer/audience, a hard fact, and an action.
- One section per screen with consistent content edges.
- Real product UI / meaningful diagrams rather than fake dashboard placeholders.
- Correct image rendering, no empty visual backgrounds, no duplicate visual reused as filler.
- Keyboard navigation, focus state, labels, headings, alt text, contrast and share metadata.
- Performance check and no layout shift / excessive WebGL contexts.
- Taste Skill finish gate report with all remaining FAILs and waivers explained.

Uibrik also requires checking the installed component in both light and dark themes and at phone width.
