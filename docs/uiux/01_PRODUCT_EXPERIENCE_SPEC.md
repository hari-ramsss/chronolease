# QoreLease UI/UX Product Experience Specification

**Status:** Design specification for review  
**Product:** QoreLease  
**Audience:** Product owner, UX designer, frontend agent, smart-contract/provider-service engineers  
**Design references:** Taste Skill (`design-taste-frontend`, main branch) and Uibrik  
**Implementation status:** Phase 1 local vertical slice exists; live Diana integration remains unverified.

---

## 1. Product definition

QoreLease is an agentic capacity-reservation and service-settlement protocol for measurable API and AI-inference capacity. A buyer describes a workload and service-level requirements, compares provider offers, accepts a provider/slot, and commits fUSD through the EVM escrow. The Native registry is intended to own provider-side registration, application collateral, capacity slots, and reservations. A provider adapter checks the reservation before dispatching work. Delivery reports are submitted for settlement.

**Core product promise:**

> Find capacity that fits the job, reserve it against a provider commitment, and settle the payment against measured delivery.

Do not lead with vague claims such as “trustless AI,” “guaranteed AI correctness,” or “proof of GPU ownership.” QoreLease can enforce provider-declared capacity among participating applications and can settle against defined service-level evidence. It does not prove physical GPU inventory, and current monitoring code does not yet provide real cryptographic monitor signatures or quorum.

## 2. Critical product-language decision: auction vs. offer round

The owner's desired experience is competitive procurement: providers compete to fulfil a buyer's AI-service requirement. The visual language can communicate competition, speed, scarcity, and a winner being selected.

However, **the current Phase 1 contract interface is not a complete on-chain auction implementation**. The documented EVM operations are `createRequest`, `acceptOffer`, `reserveCapacity`, `submitEvidence`, `settle`, `refund`, and `getJobStatus`. The flow binds a request to a provider and slot. There is no implemented on-chain `submitBid`, bid commitment/reveal, auction close, automatic winner selection, or bid history state machine. Provider discovery and offer collection are not established as on-chain functionality either.

Therefore, the initial UI specification must use these terms:

- **Provider offers / competitive offer round / request for offers** for the buyer-facing comparison workflow.
- **Accept offer** for the action that creates the buyer's escrow and invokes Native reservation.
- **Reservation** only after a valid Native response is received and the EVM transaction succeeds.
- **Auction** only if a later, explicit product/contract design adds auction mechanics and the relevant off-chain service. Do not make the UI imply sealed bidding, live bidding, auction expiry, automatic winner selection, or an on-chain auction result before those features exist.

A time-boxed offer window may be shown as an off-chain marketplace feature only after its API and persistence model are implemented. It must not be mistaken for a Native/EVM contract-enforced auction deadline.

## 3. Product audiences and jobs to be done

### 3.1 Buyer: AI product owner / agent operator

Needs to:
- Describe the job in operational terms: service type, unit count, time window, throughput, latency target, success-rate target, and maximum spend.
- Compare providers on price and measurable service attributes, not marketing language alone.
- Understand the offer terms and exactly what is being reserved.
- See the fUSD amount that will be escrowed before authorizing a transaction.
- Track execution, evidence, payment, refund, or failure without needing to understand every chain primitive.

### 3.2 Provider: API / inference operator

Needs to:
- Register a service profile and endpoint manifest.
- Deposit and understand the liquid QOR service bond separately from delegated staking.
- Publish capacity slots with time windows and service terms.
- See reserved vs. available capacity.
- Receive only work backed by an active Native reservation.
- Understand job delivery, evidence status, payout, bond unlock, and any penalty.

### 3.3 Monitor / verifier (later role)

Needs to:
- Run independent probes against the provider service.
- Submit signed, attributable service observations.
- See which job, terms hash, and time window a report belongs to.
- Understand the difference between an observed metric, a monitor signature, an accepted evidence policy, and final settlement.

This role is not a fully independent cryptographic quorum in the current Phase 1 implementation. Do not design it as a completed multi-party verification product yet.

### 3.4 Operator / administrator

Needs to:
- Configure authorized escrow identities, provider admission thresholds, bond-per-unit, penalty parameters, and monitor permissions.
- Inspect network/contract health and deployment state.
- Distinguish configuration changes from actual on-chain events.

Admin functions should not dominate the primary buyer or provider experience.

## 4. Information architecture

### Public website

1. Home
2. Marketplace preview / Explore capacity
3. How it works
4. For buyers
5. For providers
6. Protocol / architecture
7. Documentation
8. Connect wallet / Open app

### Authenticated application

**Global navigation:** workspace switcher, network status, connected account, notifications, help, profile.

**Buyer workspace:**
- Overview
- Explore providers
- Requests
- Offers
- Reservations & jobs
- Payments / activity
- Settings

**Provider workspace:**
- Overview
- Services
- Capacity slots
- Reservations & jobs
- Bond & eligibility
- Delivery / performance
- Payouts & activity
- Settings

**Operator workspace (restricted):**
- Protocol configuration
- Authorized monitors
- Network / contract status
- Audit activity

Navigation labels can be refined after user research, but the primary mental model must remain buyer vs. provider. Do not combine buyer and provider tasks into one dense dashboard without a clear workspace switch.

## 5. End-to-end buyer journey

1. **Arrive:** landing page explains the product in one sentence and shows a clear example of provider competition.
2. **Connect:** connect the supported QoreChain wallet path and confirm the selected network. Explain when Native and EVM account capabilities are required. Never ask users to paste a recovery phrase into the app.
3. **Describe job:** create a request with service type, quantity, time window, latency/availability targets, and spend ceiling.
4. **Discover / receive offers:** show matching providers and their offers. In Phase 1 this must be identified as a marketplace/provider-service layer, not an on-chain auction.
5. **Compare:** let the buyer compare price, available capacity, latency, throughput, success rate, service window, bond/eligibility status, and terms hash / manifest details.
6. **Review:** show the selected provider, slot, terms, unit count, price per unit, total fUSD escrow, wallet/authorization requirements, and cancellation/refund policy.
7. **Accept:** trigger wallet authorization and EVM `acceptOffer`. Display sequential transaction states without claiming success early.
8. **Reserve:** show “Reserved” only after the EVM transaction succeeds and the Native response is validated.
9. **Execute:** provider adapter checks the reservation and dispatches the workload.
10. **Observe:** show request counts, failures, latency, completion and evidence status with provenance.
11. **Settle:** explain provider payment and buyer refund based on accepted delivered units. Show bond action only if the actual EVM-to-Native `accepted_breach` path is implemented and verified.
12. **Close:** show a final receipt containing request/job ID, provider, slot, terms hash, transaction links, measured delivery, provider payout, refund, and evidence references.

## 6. End-to-end provider journey

1. Register provider identity and service profile.
2. Connect an endpoint manifest and describe supported service class.
3. Complete Native staking-eligibility check (the runtime semantics are still unverified on Diana).
4. Deposit liquid QOR service bond. Clearly explain that this is application collateral and not validator delegation.
5. Publish time-bounded capacity slots.
6. Receive buyer requests / offer opportunities through the provider marketplace layer.
7. Submit an offer with price and service terms (only once the offer submission backend exists).
8. When accepted, verify that Native reservation is active before dispatching work.
9. Execute job and record operational metrics.
10. Submit service evidence through the configured monitor/evidence path.
11. Receive settlement, unlock remaining bond, or review a penalty/dispute.

### 6.1 Motion and scroll-story principle

The public landing page should have one signature, scroll-driven product story if the current Taste Skill scene dealer finds a scene whose requirements match the actual QoreLease UI assets. The visual stage may remain anchored while its foreground interface and active chapter change with the visitor’s normal vertical scroll. This is a self-contained scene, not a site-wide fixed background or a blanket animation applied to every section. The rest of the public page stays calm.

The authenticated buyer/provider application should prioritise task completion. Use state-driven micro-interactions and timelines tied to real events; do not import marketing-page scroll choreography into operational forms, offer tables, wallet confirmation or job management. See `05_SCROLL_STORYTELLING_AND_CREATIVE_AUTONOMY.md`.

## 7. Core experience principles

- **Buyer certainty before signature:** no surprise fUSD transfer; show full amount and terms before wallet approval.
- **Truthful status:** distinguish “request created,” “EVM funded,” “Native reserved,” “provider running,” “evidence submitted,” “evidence accepted,” and “settled.”
- **One source of truth:** chain state is authoritative for bonds, capacity, reservations, escrow and settlement. Off-chain services may cache or index it but cannot invent it.
- **Explain the two runtimes only where useful:** translate technical operations into a clear activity timeline, with an expandable “Protocol details” panel for advanced users.
- **Comparability:** put price, throughput, latency and service window in consistent fields so offers can be evaluated quickly.
- **No false certainty:** a monitor signature proves who made a statement, not that the statement is true. Current local deterministic digests are not signatures or quorum.
- **Progressive disclosure:** ordinary buyers see outcome and risk; developers can expand hashes, contract calls, transaction IDs and raw evidence.
- **Accessible motion:** motion gives feedback and explains state changes; it is never the only way to understand an event.

## 8. Capability truth table for the UI

The frontend must use explicit capability flags and status sources. Do not hardcode future functionality as live.

| Capability | Phase 1 reality | UI treatment until verified |
|---|---|---|
| Native provider registration / slot / bond / reservation code | Implemented locally; no Diana deployment | Demo/local status in preview; production status unavailable until contract deployed |
| Staking eligibility | `StakingQuery` helper and local mock tests; Diana semantics unverified | “Eligibility check unavailable / not verified on this network” until live query succeeds |
| EVM fUSD escrow | Solidity implementation and local mocks | Simulated/demo until token address and live contract deployment are confirmed |
| EVM-to-Native bridge | Local stateful mock tests; response encoding and mapped sender unverified | “Test mode” or disabled integration state until G0-C/G0-D pass |
| Provider offer discovery | Not established by Phase 1 contract methods | Label as preview or connect actual offer service before showing live offers |
| On-chain auction / bid lifecycle | Not implemented | Do not call a request/offer round an on-chain auction |
| Provider adapter | Local adapter with in-memory Native client and OpenAI-compatible mock | Show local demo / simulated workload, not live provider execution |
| Monitor attestations | Deterministic local digests; not real signatures or quorum | “Report submitted” / “Demo evidence”; no “independently verified” badge |
| SLA penalty | Native penalty code exists; actual EVM breach-decision path requires verification | Do not show “bond slashed” or guarantee penalties until end-to-end path is proven |
| Physical hardware / model correctness | Not proven | Never claim hardware ownership or arbitrary AI-answer correctness |

## 9. Trust and transparency vocabulary

Prefer:
- “Provider-declared capacity”
- “Capacity reserved”
- “Measured latency”
- “Delivery report received”
- “Evidence accepted by configured policy” (only if the policy actually accepted it)
- “Settlement confirmed” (only after transaction receipt and expected state)
- “Testnet / simulated / local demo” where applicable

Avoid unless demonstrated:
- “Guaranteed GPU capacity”
- “Trustless AI verification”
- “Independent 2-of-3 monitor verification”
- “Auction winner” as an on-chain result
- “Bond slashed” when the actual breach parameter is not wired and tested
- “Live” or “real-time” when the data is sampled, cached, or mocked.

## 10. Product acceptance criteria for the UX

The design is ready for implementation review when:
- The public landing page explains the product and main action in its first viewport.
- Buyer and provider journeys are separately mapped from entry to completion.
- A buyer can understand the offer comparison and total escrow before signing.
- Reservation and settlement status are never conflated.
- Wallet/network failure, authorization expiry, bridge failure, capacity rejection, execution failure, evidence pending, refund, and settlement states are designed.
- Every claim in copy maps to a real implementation or is labelled as illustrative / planned.
- The responsive flow works at desktop, tablet and narrow phone widths.
- Accessibility and reduced-motion behaviour are documented.
- The product owner approves the visual direction before the frontend agent builds every screen.
