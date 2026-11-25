# QoreLease UI/UX Design Pack

This package translates QoreLease's Phase 1 architecture into a frontend product experience and implementation handoff. It uses the current Taste Skill and Uibrik documentation, while preserving the current project's technical limitations and truth boundaries.

## Documents

1. **`01_PRODUCT_EXPERIENCE_SPEC.md`** — product definition, user roles, UX principles, information architecture, complete journeys, capability truth table and acceptance criteria.
2. **`02_SCREEN_MAP_AND_USER_FLOWS.md`** — landing page, buyer workspace, provider workspace, transaction progression, states, errors and responsive behavior.
3. **`03_VISUAL_LANGUAGE_AND_MOTION.md`** — art direction, provider-character hero concept, motion system, accessibility and Uibrik component shortlist.
4. **`04_AGENT_TOOLING_AND_HANDOFF.md`** — Taste Skill and Uibrik workflow, MCP/install guidance, frontend agent handoff, and QA checklist.
5. **`05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md`** — the fixed-stage, native-scroll product story, Taste Skill big-scene rules, motion architecture, Uibrik complements, and explicit creative freedom for the agent.

## Key product decision

The design uses a competitive provider-offer experience. The current Phase 1 contracts do not implement a complete on-chain bidding/auction mechanism. The UI must not claim sealed bidding, on-chain bid submission, automatic winner selection or auction settlement until those capabilities exist. The provider sprint in the hero must be labelled as a demonstration when it uses illustrative data.

## Motion and creative direction

The landing page should explore one carefully composed scroll-driven product scene: the visual stage stays anchored while the product UI and active chapter change with native vertical scroll. This is one isolated big scene/effect, not generic scroll-reveal animation across every section. The current Taste Skill 2.5.1 dealer and scene metadata determine whether the scene is suitable and which additional moments are allowed. See Document 5 for the exact scroll-story, motion-budget and creative-autonomy rules.

The provider-character “sprint” is an initial creative concept, not a fixed design mandate. The agent is expected to explore materially different directions and recommend a stronger option if it finds one. It has room to invent a better visual metaphor, character system, composition or motion treatment, while preserving product truth and accessibility. See Document 5.

## Recommended use

1. Review the product and flow documents.
2. Review the motion/storytelling and creative-autonomy addendum.
3. Let the agent prepare three distinct visual directions and recommend one.
4. Approve the overall direction and any paid Uibrik components.
5. Have the coding agent load the current `design-taste-frontend` skill and use Uibrik's live MCP/catalogue.
6. Authorize frontend implementation only after the design direction is approved.

The documents are design guidance. They do not change contracts, deploy infrastructure, or establish that Diana integration is live.
