# QoreLease Screen Map and User Flows

**Purpose:** Translate the product specification into a screen-by-screen frontend blueprint.  
**Scope:** Public marketing site, buyer app, provider app, transaction states, and empty/error states.  
**Important:** All sample values and provider personalities in visual concepts must be clearly marked as illustrative until backed by live data.

---

## 1. Public landing page: from first impression to app entry

### Screen 1 — Hero: “Capacity is competing. Your requirements decide.” (exploration direction, not a fixed composition)

**Primary message:** “Reserve AI service capacity. Settle against measured delivery.”

**Supporting copy:** “Compare provider offers for inference and API workloads, reserve a service slot, and keep payment tied to the job’s agreed terms.”

**Primary CTA:** `Explore capacity`  
**Secondary CTA:** `See how QoreLease works`

**Hero composition:**
- A real, responsive mini product surface, not a fake dashboard assembled from decorative boxes.
- One request card in the visual centre: e.g. “Document extraction · 500 requests · 15-minute window · latency target.”
- One proposed direction uses three stylized provider-agent characters entering on distinct lanes. This is a concept seed, not a mandatory composition: the agent may propose a stronger visual metaphor or a character-free approach after creative exploration. If characters are used, they represent provider archetypes, not actual named providers: `Latency-first`, `High-capacity`, and `Cost-efficient`.
- Each competitor reveals an offer tile with comparable metrics: price, capacity, p95 latency, success rate, and window.
- The buyer’s criteria determine which offer is highlighted. The animation should visually communicate comparison and selection, not imply random bidding or on-chain auto-award.
- The scene ends with the chosen offer snapping into a “Ready to review” request card.
- Include an obvious `Replay demo` control when the scene is timed/replayable and a “Illustrative demo data” label whenever values are not live.

**Motion purpose:** Explain how competing provider offers respond to a buyer’s request. The characters are an expressive wrapper around real product data, not the entire interface.

### Screen 2 — The problem / market need

Headline: “AI capacity is easy to request. Reliable capacity is harder to reserve.”

Show three concrete problems:
- Provider capacity can be oversold across disconnected applications.
- Buyers need comparable service terms before committing funds.
- Payment and delivery evidence need a consistent settlement path.

Use one visual per claim. Avoid three identical feature cards; follow Taste Skill’s requirement for a deliberately planned section rhythm.

### Screen 3 — How it works

Use a six-step sequence:

1. Define the workload.
2. Compare provider offers.
3. Accept the provider and terms.
4. Reserve Native capacity and escrow EVM payment.
5. Execute and measure delivery.
6. Settle or refund against accepted evidence.

Each step should have a concise user-facing explanation and an expandable technical detail. Do not suggest that all steps are already live on Diana.

### Signature scroll scene — “One request, from brief to settlement”

Give the landing page one dedicated scroll-driven scene, subject to the current Taste Skill scene dealer and its asset requirements. The target feeling is that the stage/background remains steady while the visitor scrolls normally and the product UI in front of it changes step by step. This must be a single intentional scene, not a page-wide fixed background or a generic fade-up on every section.

**Suggested chapter sequence (illustrative; agent may improve it):**
1. Job brief — service type, units, service window, targets and buyer budget.
2. Provider offers — comparable provider offers arrive; the buyer’s selected priorities clarify the preferred fit.
3. Reservation and escrow — the selected slot and intended Native/EVM commitment are shown as separate but coordinated lanes.
4. Execution and settlement — measured workload results and evidence lead to a final payment/refund view.

Use the actual QoreLease interface rendered as HTML. Keep the scene stage and background visually consistent; update only the relevant foreground UI, active step and explanatory copy. End on a concrete action such as `Review offer` or `Accept offer & reserve capacity`, not an invented “auction won” state.

The current Taste Skill `scenes.md` includes `product-assembles-into-its-action` for software/tech pages, requiring the product’s own UI and 4–6 steps. It is a promising candidate, not a forced selection. The agent must run the current scene dealer, inspect the selected scene’s `needs`, `fits`, `meta.json` and `scene.js`, and use the skill’s own scene mounting pattern. If no scene genuinely fits the available QoreLease UI, use a different valid dealt moment or keep this section static.

**Fallbacks:** On phones, reduced motion, JavaScript failure or scene-load failure, render the complete static screen and the full ordered step list. Keep normal browser scrolling; provide a skip link to the next section. Do not hide the product story behind a scroll-only script.

### Screen 4 — Why two runtimes?

Use a clear two-lane diagram:

**Native lane:** provider identity → application bond → capacity slot → reservation state.  
**EVM lane:** buyer request → fUSD escrow → settlement / refund.  
**Synchronous bridge:** the EVM transaction requests a Native reservation; success or failure must be atomic when the live bridge is verified.

The diagram must label “Architecture design” / “Testnet integration pending” until the deployed registry and bridge path are proven.

### Screen 5 — Buyer and provider value

Two unequal, editorially composed panels:
- Buyers: compare offers, bind terms, control spend, track measured delivery.
- Providers: publish capacity, reserve commitments, prevent participating-app overbooking, receive settlement.

Keep the panel content grounded in actual Phase 1 functionality and clearly label features that depend on future offer-discovery services.

### Screen 6 — Evidence and limitations

A trust section that is unusually honest:
- Native state is intended to be the authoritative reservation ledger.
- Provider-declared capacity is not physical hardware attestation.
- Service-level metrics are not proof of arbitrary model-output correctness.
- Monitor signature/quorum is future work; current Phase 1 local monitor attestations are deterministic digests.

This honesty is a differentiator, not a weakness. It makes the product credible.

### Screen 7 — Final CTA and footer

CTA: `Explore provider offers` / `Register as a provider`.  
Footer: Product, docs, protocol status, source repository, network information, terms/privacy. Avoid unsupported social-proof logos, fake customer names, or invented metrics.

---

## 2. App shell and global states

### Global top bar

- QoreLease mark and workspace name.
- Buyer / Provider workspace switcher.
- Network indicator: `Diana testnet`, `Disconnected`, or `Network status unavailable` based on live provider response.
- Wallet account indicator with safe short address display.
- Notification centre.
- Account/help menu.

### Network and wallet banners

Design explicit banners for:
- Wrong EVM network.
- Native account not connected.
- EVM account not paired / wrong address.
- EVM authorization window missing or expired.
- Contract address not configured.
- Native target not allowlisted.
- Bridge call unavailable.
- Staking-query capability unverified.

Do not make the wallet connect CTA look like a normal marketing sign-up; it is a security-sensitive action. Never request seed phrases or private keys.

### Global transaction activity drawer

Show each action as a traceable sequence:
- Awaiting user approval.
- EVM transaction submitted.
- EVM transaction confirmed.
- Native operation accepted / rejected (only when real response exists).
- Final state confirmed.

For failure, show the exact failed stage and whether the EVM transaction reverted. Keep block height, transaction hash, and explorer link in an expandable advanced section.

---

## 3. Buyer workspace screens

### B1 — Buyer overview

Primary content:
- Active reservations.
- Open requests / offers received.
- Amount currently escrowed.
- Recent jobs awaiting evidence or settlement.
- Recent activity.

Do not show invented market-wide metrics. Empty-state text should help users create their first request.

### B2 — Explore providers

Core layout:
- Search / service-type filter.
- Filters for capacity, region if supported by provider data, latency, throughput, success rate, availability window, and price.
- Provider result list with comparison values in consistent columns.
- Provider detail preview with endpoint manifest hash, service type, published slots, and last-updated timestamp.

Each result needs a data freshness indicator. No “online” or “available now” status without an actual fresh check.

### B3 — Create request wizard

Use a focused 4-step wizard, not one giant form:

**Step 1: Workload**
- Service class / API type.
- Units or request count.
- Input/output profile if relevant.

**Step 2: Service window**
- Start and end time.
- Time zone clearly visible.
- Slot duration and deadline.

**Step 3: Service targets**
- Maximum latency / p95 target.
- Minimum success rate.
- Throughput / concurrency requirement.
- Optional monitor probe profile, only if implemented.

**Step 4: Budget and review**
- Maximum budget.
- Currency fUSD.
- Terms summary.
- Hash/immutable terms preview.
- Submit request / start offer round.

Use numeric controls with sensible units and constraints. A dial is only appropriate for a bounded threshold such as max latency or target utilization; normal text/numeric fields must remain available for exact entry and keyboard users.

### B4 — Offer comparison

This is the main competitive procurement screen.

Offer row/card data:
- Provider identity/avatar.
- Service type and manifest/version.
- Offered capacity and remaining capacity.
- Price per unit and total cost.
- p95 latency / measured success rate (label source and sample window).
- Service window.
- Native eligibility / bond status (only if on-chain query is available).
- Terms hash and last-updated timestamp.

Sorting choices: best fit, lowest cost, lowest latency, highest capacity. Avoid a single opaque “AI score” unless its formula is shown. “Recommended” should explain the criteria it prioritizes.

Actions: `Compare`, `View provider`, `Accept offer`.

**Auction caveat:** until an auction engine exists, this screen is a quote/offer comparison UI. Do not show a countdown, sealed bid, bid reveal, automatic winning bid, or “auction closed” state as if the chain enforces it.

### B5 — Offer details / acceptance review

Show:
- Provider and slot identity.
- Exact units reserved.
- Price per unit and total fUSD.
- Service window.
- Terms / manifest hash.
- Delivery targets.
- Refund / settlement rules.
- What will happen in Native and EVM.

The final CTA should read `Accept offer & reserve capacity`. The confirmation panel must state the exact fUSD amount and explain that the Native reservation and EVM escrow are intended to commit atomically.

### B6 — Wallet confirmation and reservation progress

A sequential visual, not a fake “instant success” animation:
1. Check wallet and network.
2. Request EVM signature.
3. Submit EVM transaction.
4. Call Native through the bridge.
5. Decode and validate response.
6. Mark reservation confirmed.

If the Native call fails, show “Reservation rejected; EVM transaction reverted” only when the actual receipt confirms the revert. If the RPC fails before a reliable result, show “Outcome unknown; refresh chain state” instead of guessing.

### B7 — Reservation / job detail

Information layout:
- Job header: provider, job ID, service, reserved units, state.
- Progress timeline: Created → Funded → Reserved → Running → Evidence → Settled / Refunded.
- Native card: slot, reserved vs. available units, bond locked.
- EVM card: fUSD escrow, paid, refunded, remaining.
- Terms: hashes, start/end, price.
- Execution telemetry: requests completed, failures, p95 latency, success rate, measurement interval.
- Evidence panel: source monitor(s), signatures/status, report hash, time received.
- Chain activity: transaction hashes and heights.

Use separate labels for `Provider execution`, `Evidence`, `Native reservation`, and `EVM settlement` so a user cannot mistake one for another.

### B8 — Settlement receipt

- Total reserved units.
- Accepted delivered units.
- Provider payout.
- Buyer refund.
- Remaining/unconsumed units.
- Bond release/penalty (only if proven).
- Accepted evidence reference.
- EVM and Native transaction references.

If monitor quorum is not implemented, show the exact configured evidence acceptance state; don't add a “2 of 3 verified” visual.

---

## 4. Provider workspace screens

### P1 — Provider overview

- Published capacity.
- Reserved capacity.
- Available capacity.
- Active jobs.
- Bond available vs. locked.
- Recent performance metrics.
- Pending offer requests.

Each metric has a source and data freshness.

### P2 — Provider registration

Sections:
- Provider display name / provider ID.
- Service profile.
- Endpoint and manifest metadata.
- Service type.
- Terms hash.
- Stake eligibility result (pending/eligible/ineligible/unavailable).
- Registration transaction status.

Do not show a verified/eligible badge until Native returns and validates the actual query result.

### P3 — Bond and eligibility

Show separate cards:
- Delegated QOR stake (eligibility input only).
- Liquid QOR service bond deposited into the Native contract.
- Bond available.
- Bond locked by active reservations.
- Penalties paid.

Never imply that QoreLease can slash validator delegation for SLA violations.

### P4 — Capacity calendar

- Slot creation form: service type, start/end, total units, terms hash.
- Calendar/list of published slots.
- Capacity bar: total, reserved, consumed, available.
- Conflict/overlap explanation.
- Slot status and chain reference.

### P5 — Reservation inbox / job execution

- New accepted reservations.
- Reservation validation status.
- Workload parameters and terms hash.
- `Start job` enabled only when reservation is confirmed.
- Execution metrics and errors.
- Report submission state.

The provider adapter must not accept a job just because its own database says it is booked.

### P6 — Performance and evidence

- Time-series latency and success metrics.
- Measurement window and monitor source.
- Evidence reports and accepted/rejected status.
- Clearly distinguish local/demo attestations from cryptographically signed production reports.

### P7 — Provider settlement

- Job settlement history.
- fUSD payouts (if provider payout rail is configured).
- Bond locked/unlocked.
- Penalties/refunds with event and transaction references.

---

## 5. Required state catalogue

Use one normalized UI state layer derived from current contract and service state. Avoid inventing UI-only states that contradict the contracts.

### Request / offer layer (marketplace service)

- Draft
- Submitted
- Collecting offers (only after this service exists)
- Offers available
- Offer selected
- Expired / Cancelled

### EVM job state (documented Phase 1)

- `None`
- `Created`
- `Funded`
- `Reserved`
- `Settled`
- `Refunded`

### Native reservation state (documented Phase 1)

- `ACTIVE`
- `FINALIZED`
- `RELEASED`

### Execution / evidence UI state (off-chain)

- Not started
- Running
- Completed / report pending
- Report submitted
- Evidence accepted / rejected / unresolved

These are distinct sub-states; don't flatten them into a single “job status” without a clear combined label.

---

## 6. Required empty, loading, and failure screens

- No providers found.
- No offers received yet.
- Provider has no capacity slots.
- Insufficient/locked bond.
- Staking query unavailable / unsupported.
- Wrong network.
- Native wallet not connected.
- EVM wallet not connected.
- EVM authorization window expired / missing scope.
- fUSD allowance insufficient.
- Reservation rejected due to insufficient capacity.
- Bridge call failed / empty response / malformed response.
- Transaction submitted but confirmation pending.
- Transaction result unknown due to RPC interruption.
- Provider workload failed.
- Evidence missing / invalid / duplicate.
- Refund pending / complete.
- Settlement pending / complete.
- Contract not deployed / target not allowlisted.

Every error should state: what happened, what is safe to do next, whether funds were moved, and whether the status has been verified on chain.

---

## 7. Responsive behavior

- Desktop: full sidebar + detailed comparison table and job detail two-column view.
- Tablet: collapsible sidebar, comparison cards or horizontally scrollable table with sticky key columns.
- Phone: single-column flow; each offer becomes a compact comparison card; bottom action bar only when it doesn't occlude content; forms use native keyboard-appropriate input types.
- Never use a wide multi-column table as the only mobile offer-comparison experience.
- Hero provider race collapses to three vertical or horizontal stacked provider lanes; character animation becomes reduced or static if needed.

## 8. Screen review checklist

For each screen ask:
- What is the single decision or task?
- What fact does the user need before acting?
- What is the source and freshness of each displayed value?
- Which runtime or off-chain service owns this state?
- What is the failure state?
- Can the user understand the result without seeing the animation?
- Does the screen work at 390px and with keyboard-only navigation?
