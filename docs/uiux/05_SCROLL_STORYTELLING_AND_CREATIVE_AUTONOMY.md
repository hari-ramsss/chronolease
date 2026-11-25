# QoreLease Scroll Storytelling, Motion Direction & Creative Autonomy

**Purpose:** Strengthen the QoreLease design brief with a deliberate scroll-driven product story and give the frontend/design agent room to discover a better creative direction than the first concepts in this pack.  
**Status:** Directional brief for design exploration. It is not a pixel-perfect mandate and does not authorize implementation by itself.  
**Product context:** QoreLease Phase 1 local vertical slice; Diana integration and several delivery-verification capabilities remain unverified.

---

## 1. The missing experience: a scene that stays put while the story changes

The landing page should not be a stack of static sections with generic fade-up animations. It should have at least one memorable, intentional scroll-driven scene where the visitor keeps scrolling normally while a visual stage stays in place and its foreground product elements change step by step.

The desired interaction is:

- The **stage/background remains visually anchored** for the duration of one self-contained section.
- The visitor's normal vertical scroll advances the story; the page is never hijacked or locked by a custom scrolling library.
- The active step, product UI, characters, offer rows, Native/EVM diagram, delivery evidence or final action changes as the visitor moves through the section.
- A clear progress indicator shows where the visitor is in the sequence.
- The scene has a complete, readable resting composition when motion is unavailable.

Think of it as a product explainer built into the page, not a cinematic effect placed behind unrelated copy.

**Recommended QoreLease story:** one buyer request moves through competitive provider offers, reservation, service execution and settlement. The same stage remains in view while the foreground changes to explain each transition.

## 2. How this fits the current Taste Skill (important)

The current main-branch Taste Skill is `design-taste-frontend`, identified by its `SKILL.md` as tasteskill 2.5.1. Use the current main skill and its current references at implementation time, not archived v1 or v2-experimental copies.

The current rules are more specific than “animate on scroll”:

- Every page gets a one-time hero entrance, the dealt moment(s) prescribed by the current `moments.mjs` workflow, and visible hover/press feedback on interactive elements. The current skill's page-length rules determine whether the page receives one or two moments.
- On technical/software pages, the current skill permits at most one big scroll-driven scene/effect, provided that the brief has the actual assets/content the selected scene requires. Its effect/moment budget also permits other specifically dealt moments; follow the live dealer output and `effects-usage.md`, not an invented count.
- A big scene is a **sticky stage scrubbed by native page scroll**. The rest of the page stays calm: do not make every card, row, tile or paragraph fade, rise or stagger as it enters the viewport. The current `motion.md` explicitly says scrolling moves only the dealt moment/scene, not generic reveal animations or parallax text.
- Software pages may also use the skill-approved timed hero/visual loop, card-diagram loops and a meaningful count where the current skill allows them. Do not add these just to meet a numerical quota; use them only where they explain product behavior and pass the finish gate.
- A scene belongs in its own section. Do not run it behind the entire website, through the navbar, or across unrelated content.
- The scene must have a static/rest presentation on phones, under reduced motion and when JavaScript fails. All content must remain understandable.
- Do not use scroll-jacking, custom `window.scrollY` state loops, or a smooth-scroll library that takes control away from the browser.

**Taste Skill references to read in full before building:**

- `skills/taste-skill/SKILL.md`
- `skills/taste-skill/references/motion.md`
- `skills/taste-skill/references/scenes.md`
- `skills/taste-skill/references/effects-usage.md`
- `skills/taste-skill/references/moments.md`

The skill's `scenes.md` currently identifies `product-assembles-into-its-action` as a software/tech scene that needs the product's own UI rendered at true size and 4–6 steps. It is a promising candidate for QoreLease, not an instruction to force that scene. The Taste Skill's scene dealer and actual `needs` / `fits` metadata remain authoritative. If no dealt scene fits the real assets, choose another valid moment or keep the section static; do not fake a scene that the product cannot support.

The current `scenes.md` says to deal from scenes whose `fits` match the section, whose `types` include `software`, and whose `needs` are met; the selected scene's `meta.json` and `scene.js` define its `look`, `needs`, `never`, `avoidWith`, markup and options. The agent must inspect these files and use the Taste runtime (`scenes.js`, `lib.js`, shared CSS) instead of writing a parallel scroll engine. For the candidate `product-assembles-into-its-action`, the listed requirement is the product screen rendered as HTML across 4–6 steps.

### Scene candidate for QoreLease

**Candidate:** `product-assembles-into-its-action`

Why it may fit:
- QoreLease is a software / AI procurement product.
- The scene is designed to show a real product screen building through 4–6 meaningful stages.
- It can hold a consistent stage while additional interface rows and the active explanation advance with scroll.
- The end state can resolve to one concrete action such as `Review offer` or `Accept offer & reserve capacity`.

Possible story beats if this scene is dealt and its requirements are met:

1. **Define the job** — service class, units, service window and budget appear in the request UI.
2. **Compare provider offers** — Swift/Atlas/Lean or a better agent-created visual cast introduce comparable price, capacity and latency terms.
3. **Commit the reservation** — selected provider/slot details appear alongside the intended Native reservation and EVM fUSD escrow.
4. **Run the workload** — provider adapter state and measured service metrics enter the screen.
5. **Review delivery** — report status and accepted/awaiting evidence are shown with honest provenance.
6. **Settle the job** — a receipt resolves to payment/refund and the next action.

The agent may reduce, reorder or replace these beats to fit the actual UI and the chosen Taste scene. Do not force six steps if four make a clearer story.

**Visual behaviour:** keep the scene's environment, grid, framing and camera/background stable. Change the product UI and the active explanation: panels arrive, offer rows compare, a reservation state locks, telemetry updates, and the final action becomes prominent. The persistent background should help the viewer understand continuity; the moving foreground should communicate the state transition.

**Truth rule:** use illustrative data and visibly identify it as a demo when no live provider/offers endpoint exists. Do not present a local mock, deterministic digest or unverified Diana integration as a live result. The final scene must not imply an on-chain auction, sealed bidding, an automatic winner or independent cryptographic verification unless those capabilities have actually been implemented and connected.

## 3. Landing page motion choreography

The public landing page should have a composed motion hierarchy, not motion everywhere.

### A. Hero: provider competition as the hook

Create an expressive, premium opening visual in which providers respond to one buyer request. Three characters are a starting suggestion, not a fixed requirement. The agent may invent a more distinctive metaphor, art direction or character system if it communicates the product more clearly.

Possible direction using the current concept:
- A buyer request arrives first.
- Provider archetypes enter on separate lanes.
- Each exposes the same comparable offer fields (price, units/capacity, latency, success rate and service window).
- The buyer's selected preference changes which offer is emphasised.
- The selected offer moves to a review state; it must not jump to a false “auction won” or “on-chain reserved” state.

A short timed hero loop can be used if it adds clarity. It must be finite or pauseable, have a clear replay/pause affordance, and settle into a stable resting state. Do not continuously loop operational numbers or fabricate live presence.

### B. Signature pinned scene: the product story

After the hero, create one dedicated scroll-driven section if the Taste Skill scene dealer and the actual assets support it.

Recommended composition:

- **Stage:** one anchored frame with a consistent environment/background, such as a dark technical workbench, neutral paper-like procurement canvas, or a bespoke visual world. The agent chooses the best direction after exploring the Taste Skill's dealt layouts/palettes.
- **Primary visual:** a realistic, HTML-rendered QoreLease interface, not a flattened dashboard screenshot.
- **Narrative rail:** short step headings and 1–2 lines of copy. The active step updates as native scroll advances.
- **Progress cue:** a restrained step index or line indicating the current chapter; it should not compete with the main product visual.
- **Transitions:** only the relevant foreground UI changes. The backdrop, content frame and overall visual identity remain stable, matching the requested “fixed background, changing components” feeling.
- **Close:** the final UI state resolves into one real next action, e.g. `Review offer` or `Create request`.

This scene should be the landing page's main scroll-driven signature. Do not add a second pinned narrative simply because the technology makes it possible. Additional section moments, if any, are determined by the current Taste Skill's page-length rules and moment dealer. The scene and moments must not be placed in the same or neighboring sections where the skill says they conflict; the scene remains the page's single big-scene/effect allowance.

### C. Remaining landing sections

Keep the rest of the page readable and mostly calm. Use section entrance choreography only where the current Taste Skill explicitly permits it; do not blanket every section with scroll-triggered fade-ups.

Use static diagrams, real product UI, concise illustrations, measured data and well-composed typography to explain:
- why provider-declared capacity needs a shared reservation authority;
- why buyer payment and provider capacity commitments live in different runtimes;
- what evidence is actually measured;
- what the system does and does not guarantee.

## 4. Motion on authenticated product screens

Treat the public marketing site and authenticated application as separate design contexts sharing one QoreLease token system. The Taste Skill's big-scene and marketing-page storytelling workflow is for the public software page; do not impose a pinned scroll narrative on buyer/provider dashboards, dense tables, forms or wallet flows. Buyers and providers need to complete operational tasks quickly, not sit through cinematic sequences.

Use interaction-led motion in the app:

- Offer selected → compare panel updates and selection state is unmistakable.
- Sort/filter changed → rows reorder with a brief, spatially coherent transition.
- Request accepted → transaction timeline advances only when the state source confirms it.
- Capacity reserved → capacity and bond bars update from the returned chain state.
- Job running → telemetry updates only when real new samples arrive.
- Evidence received/accepted → evidence card changes state with source, timestamp and provenance.
- Settlement confirmed → receipt reveals after the transaction receipt and expected state are verified.

Avoid scroll-pinned scenes in dense operational tables, wallet confirmation, forms, offer lists or job-detail workflows. Do not make scrolling a prerequisite to discovering controls or performing a transaction.

## 5. Motion ownership and implementation rules

Use one animation owner per visual element/property:

- **Taste Skill scene runtime / its documented scroll engine:** the one isolated pinned/scrubbed scene selected for the public software landing page.
- **Motion (`motion/react`) or simple CSS:** local UI interactions, shared-layout transitions, buttons, small status changes and offer selection.
- **Uibrik-installed component motion:** use the component's own documented animation behavior; do not layer another animation system over the same element.
- **Three.js/WebGL:** only when the dealt creative direction genuinely needs it and the Taste Skill's tech/effect budget allows it. It is not a default requirement.

Do not run GSAP/ScrollTrigger, Motion and a Uibrik component's internal animation against the same DOM properties. Do not hand-write a `window.addEventListener('scroll')` loop or set React state on every scroll frame. Use the Taste Skill's scene implementation for the pinned scene and keep it isolated from the rest of the app.

Keep motion primarily to transform/opacity and to the few additional properties allowed by the exact dealt scene. Reserve layout dimensions and reflow for normal document layout, not per-frame animation. Avoid excessive WebGL contexts and duplicated heavy animation runtimes.

## 6. Accessibility, responsive and failure behaviour

### Reduced motion

- Respect `prefers-reduced-motion` at first render.
- Do not hide any content while waiting for animation.
- Replace the pinned scene with a complete static product screen and its step list.
- Replace the hero race with a still composition or a user-controlled, non-animated selection.
- Every state remains understandable from labels, text and values alone.

### Mobile

- Do not force desktop scroll-pinning onto narrow/touch screens when the Taste scene specifies a still phone composition.
- Show a clean stacked sequence: step heading, explanation, product visual, next step.
- Preserve all offer fields and controls; no horizontal overflow or swipe-only information.
- Keep replay/pause only if the animation genuinely works on device and has a clear touch affordance.

### Keyboard and assistive technology

- All controls are keyboard-operable and have visible focus.
- The scroll scene has a skip link to the next section or equivalent accessible escape.
- The active chapter is announced without repeatedly interrupting screen-reader users on every scroll tick. Use a deliberate, polite update strategy.
- The same story is present in DOM order without animation.
- Do not communicate state using colour or movement alone.

### Runtime and load failures

- Render the scene's complete static composition before the scroll runtime mounts.
- If JS/scene mounting fails, the product UI and all step copy remain visible.
- Do not leave a blank fixed frame, invisible text or a stuck page when scene assets fail.
- Test slow loading, resize, orientation changes, page restoration and navigation away while the scene is pinned.

## 7. Uibrik: how it complements the scroll scene

Uibrik is a source-installable React component library, not a runtime-only package. Its current skill guide says to search by interaction job, read the component's Markdown twin, install through the documented shadcn registry command, adapt the installed source in place and inspect light/dark themes plus phone width.

Uibrik should supply excellent interface pieces, not replace the Taste Skill's selected big-scene runtime or QoreLease's product-specific information architecture.

Promising catalogue candidates to investigate (not mandatory selections; catalogue counts, labels and access may change). Current Uibrik catalogue listings checked 25 Nov 2026 include `scroll-highlight` (text animation), `progress-dots`, `section-pill`, `on-this-page`, `event-feed` and `split-bar`; `benchmark-race` is listed Pro. Always re-check the live component Markdown page and MCP result before installing.

| Uibrik candidate | Possible QoreLease role | Decision rule |
|---|---|---|
| `benchmark-race` (currently listed Pro) | Provider comparison / benchmark moment | Use only if a Pro license is approved and the component genuinely fits. Never recreate Pro source from a preview. |
| `scroll-highlight` | Highlight a short narrative phrase in a public explainer | Use only if its interaction does not conflict with the Taste scene. Avoid attaching it to every paragraph. |
| `progress-dots` | Chapter progress cue or short multi-step process | Verify keyboard/touch behavior and whether it adds real clarity. |
| `section-pill` / `on-this-page` | Optional page position/navigation aid on long docs or protocol pages | Don't put redundant progress navigation beside the pinned scene. |
| `event-feed` | Buyer/provider activity history | Bind only to actual event data; no fake live stream. |
| `split-bar` | Available / reserved / consumed capacity or available / locked bond | Values and labels must match contract state. |
| `status-badge` | Reservation, job, evidence and settlement states | Map only known states; include text, not colour alone. |
| `bar-list` / comparison component | Sortable offer comparisons | Explain ranking criteria; no opaque “AI score.” |

For every component selected:
1. Search the live Uibrik catalogue by the interaction job.
2. Read `https://uibrik.com/components/<slug>.md` for its exact props, license and install steps.
3. Check current Free/Pro status and dependencies.
4. Install the licensed source using its documented command.
5. Adapt it to QoreLease's real data and design tokens.
6. Verify keyboard, touch, reduced-motion and light/dark behavior.

Uibrik currently documents a React 19 + Tailwind CSS v4 + shadcn setup. Inspect the actual frontend stack before using it. Do not migrate the app wholesale just to install one component.

## 8. Creative autonomy: the brief is not a cage

The current documents contain a direction, not a final visual system. The agent is expected to contribute design judgment and may exceed the concepts shown here.

### What the agent may change or invent

- New visual metaphors for competitive capacity procurement.
- A different character/mascot system—or no characters—if another idea is more distinctive and credible.
- Alternative hero compositions and section ordering.
- An original type, palette and surface system selected through the Taste Skill workflow.
- More interesting ways to dramatize provider comparison, Native reservation and EVM escrow.
- Custom CSS/SVG/Canvas/3D work when the brief, Taste Skill rules, performance budget and accessibility justify it.
- Better information architecture, micro-interactions and Uibrik component choices.
- A better story sequence than the illustrative four-to-six beats above.

### What the agent must preserve

- The real product proposition: reserve measurable API/AI-service capacity against provider commitments and settle against defined delivery evidence.
- Buyer and provider tasks must remain obvious and usable.
- All product capabilities, metrics, statuses and chain results must be truthful.
- Auction/bidding claims must match implemented mechanics; a request-for-offers flow is not silently described as a complete on-chain auction.
- Monitor hashes are not cryptographic signatures or quorum.
- No claim of physical GPU ownership or arbitrary AI-output correctness.
- Wallet, network and transaction safety; never ask for seed phrases or private keys.
- Accessibility, responsive behavior, reduced motion, performance and the Taste/Uibrik license rules.

### Required creative exploration

Before committing to a final landing-page direction, the agent should explore at least three meaningfully different visual concepts, not three colour variations of the same layout. For example:

1. **Provider Sprint:** characters/agents competing to fulfil one brief.
2. **Capacity Exchange:** a precise, editorial procurement board where offers stream into a stable buyer request.
3. **Reservation Machine:** a persistent technical stage showing a request transforming into a cross-runtime reservation and settlement flow.

These are starting prompts only. The agent can replace all three with stronger concepts.

For each concept, state:
- the central metaphor and emotion;
- hero composition and primary product visual;
- scroll-scene idea (or why no scene is better);
- motion signature;
- typography/palette direction;
- how the design remains credible for a financial/procurement product;
- which Taste Skill and Uibrik resources support it;
- any Pro license or significant technical cost.

Recommend one direction and explain why. The owner should approve the overall direction and any paid Uibrik component. The agent should not ask permission for every small spacing, type-scale, component, or easing decision.

### Design decision record

Create `docs/ui-ux/DESIGN_EXPLORATIONS.md` with the three directions, references, recommendation, and what the agent deliberately chose not to use. After owner approval, record the final direction in `DESIGN_DECISIONS.md`.

## 9. Agent freedom and approval boundaries

The frontend agent is a design collaborator, not a pixel-by-pixel executor. It may go beyond the examples in this pack when it can improve clarity, distinctiveness, usability or quality.

**Agent can decide autonomously:** component composition, layout details, responsive refinements, micro-interactions, motion timings within the skill's guidance, iconography, data visualisation style, typography hierarchy, visual metaphors and non-Pro component selection.

**Ask the owner before:** purchasing/using Pro Uibrik source, changing product claims or core user journeys, introducing a new runtime/backend, making a major branding decision that conflicts with approved identity, using external paid assets, or changing contract/business logic.

**When deviating:** explain the design problem, show the alternative, cite the relevant Taste/Uibrik reference or explain why a custom design is better, and capture the decision. Do not quietly ignore the product truth table or accessibility requirements.

## 10. Final creative and QA standard

A successful result should feel like QoreLease—not a generic fintech template, not a Web3 admin panel and not a game UI pasted over an escrow contract.

The public site should have one unmistakable first-screen idea, one memorable motion story, a real product visual, strong copy and a clear way into the app. The actual application should feel calm, precise and operationally trustworthy.

Required QA:
- Taste Skill browser checks and finish gate for public pages.
- Uibrik installed-component review in light and dark themes and on phone width.
- Screenshots at 1440, 1024, 768 and 390; check 320px overflow.
- Full motion pass with normal motion and `prefers-reduced-motion`.
- Keyboard-only and screen-reader checks for the pinned scene and all controls.
- Verify no blank/frozen stage, no scroll trap, no layout shift and no hidden content on JS failure.
- Keep a motion inventory: trigger, purpose, implementation owner, duration, pause/replay, reduced-motion behavior and fallback.
- Keep product truth explicit: demo data vs. provider data, local adapter vs. live provider, unverified Diana status vs. confirmed chain state.

## 11. Sources

### Taste Skill (current main branch; checked 25 November 2026)
- Repository: <https://github.com/Leonxlnx/taste-skill>
- Current skill: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/SKILL.md>
- Motion reference: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/references/motion.md>
- Scenes reference: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/references/scenes.md>
- Moments reference: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/references/moments.md>
- Scene candidate source: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/assets/scenes/product-assembles-into-its-action/scene.js>
- Scene candidate demo: <https://raw.githubusercontent.com/Leonxlnx/taste-skill/main/skills/taste-skill/assets/scenes/product-assembles-into-its-action/demo.html>

### Uibrik (catalogue checked 25 November 2026)
- Website: <https://uibrik.com/>
- Skill guide: <https://uibrik.com/skill.md>
- Component catalogue: <https://uibrik.com/llms.txt>
- MCP endpoint: <https://uibrik.com/mcp>
- Installation: <https://uibrik.com/docs/installation>
- Pro licensing: <https://uibrik.com/docs/pro.md>
