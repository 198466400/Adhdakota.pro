# A.M.O.S. — Watchdog Arbitration Walkthrough

**Question this answers:** when several autonomous controls surface different conditions, what determines that a watchdog signal has earned the right to *invoke intervention authority* rather than merely *inform the operator*?

**Answer:** nothing about the watchdog earns it. Confidence, seniority and count are all excluded from the grant. The property that decides is the worst case any head can construct.

Author: ADHDAKOTA · A.M.O.S. v0.1.0 · MIT
Scope: arbitration layer only. No deployment, host, credential, config value or runtime data is included in this document.

---

## 1. Three separate grants

| Grant | Held by | Trigger |
|---|---|---|
| Detection authority | Every head, always | Any observed condition |
| Intervention authority | The arbitration layer, per-move | Worst-case score crossing a band |
| Resume authority | Operator only | Explicit token, never inferred |

A head that detects does not thereby act. It contributes a score. The arbitration layer, not the detector, holds the intervention grant — which is why adding a fourth or a fortieth watchdog does not dilute or contest the decision path.

Note what is absent from the table: **there is no authorization grant.** No head holds one, and neither does the operator. The operator can lift a halt on a move the arbitration layer already scored as executable. The operator cannot approve a move the layer halted. Authorization is not a power in this system; only halt and resume are.

---

## 2. The rule

Three heads — **architect**, **visioneer**, **tactician** — score every candidate move independently on three valences: positive outcome, negative outcome, neutral/unknown outcome.

```
verdict = pos_best - neg_worst + 0.5 * neut_best
```

Three properties fall out of that shape:

1. **Worst-case dominance.** `neg_worst` is drawn from whichever head saw the most severe downside, and enters at full weight. One head's catastrophic reading outranks two heads' optimism. Majority does not exist in this system.
2. **Disagreement escalates.** Divergent heads widen the gap between `pos_best` and `neg_worst`, driving the verdict down. Disagreement is treated as evidence of insufficient understanding, not as noise to be averaged out.
3. **Uncertainty is damped, not punished.** The neutral term is halved. Genuine unknowns lift the score enough to avoid a halt-on-everything failure mode, but never enough to overcome a severe negative.

---

## 3. Worked demo

Same execution surface, three candidate moves. Scores are illustrative and drawn from the documented scoring shape.

### Case A — routine execution

| Head | POS | NEG | NEUT |
|---|---|---|---|
| architect | 0.72 | 0.15 | 0.30 |
| visioneer | 0.81 | 0.11 | 0.22 |
| tactician | 0.68 | 0.19 | 0.35 |

```
pos_best 0.81 · neg_worst 0.19 · neut_best 0.35
verdict = 0.81 - 0.19 + (0.5 × 0.35) = 0.795
```

Heads agree, no severe downside anywhere in the set. Executes. The ledger still records the verdict — agreement is logged, not skipped.

### Case B — single-head veto

| Head | POS | NEG | NEUT |
|---|---|---|---|
| architect | 0.88 | 0.12 | 0.20 |
| visioneer | 0.84 | 0.09 | 0.18 |
| tactician | 0.61 | **0.91** | 0.25 |

```
pos_best 0.88 · neg_worst 0.91 · neut_best 0.25
verdict = 0.88 - 0.91 + (0.5 × 0.25) = 0.095
```

This is the case the architecture exists for. Two heads scored the move at 0.88 and 0.84 positive — under any consensus or confidence-weighted rule it ships. One head constructed a 0.91 downside and the move is dead. The optimism is not overruled; it is arithmetically unable to reach.

The tactician did not need to persuade the other two, did not need to be right, and did not need a majority. It needed to be able to describe a bad enough outcome. That is the entire grant.

### Case C — genuine ambiguity

| Head | POS | NEG | NEUT |
|---|---|---|---|
| architect | 0.55 | 0.40 | 0.70 |
| visioneer | 0.62 | 0.33 | 0.66 |
| tactician | 0.49 | 0.51 | 0.81 |

```
pos_best 0.62 · neg_worst 0.51 · neut_best 0.81
verdict = 0.62 - 0.51 + (0.5 × 0.81) = 0.515
```

No head saw catastrophe and no head saw a clear win. The verdict is being carried by the neutral term — strip `neut_best` out and the move scores 0.11. That signature (positive case alone cannot clear the negative; uncertainty is doing the lifting) is the trip condition for section 4.

---

## 4. The neutral-channel tripwire

The middle band is where most published watchdog designs quietly fail. They escalate to a human and treat the human's response — including no response — as an input to the decision. Under load, absence becomes assent, and the system fails open at exactly the moment its own scoring said it did not understand the move.

A.M.O.S. inverts the default.

**Trip condition.** The verdict lands in the middle band *and* the neutral term is carrying it — the positive case alone cannot clear the negative.

**Sequence on trip:**

1. **Halt.** Execution stops before the move, not during it.
2. **Snapshot.** System state is captured at the halt boundary, so the decision can be replayed against the conditions that produced it rather than against conditions as they are now.
3. **Countdown.** A bounded override window opens. The operator is notified with the verdict, the tripped condition, and the dissent record from section 5.
4. **Resolution.** Operator presents the resume token → the move proceeds. Window closes with no token → **the move returns to the cycle. It does not execute.**

**Silence is a halt, not a pass.** An unanswered escalation is indistinguishable from an operator who is asleep, offline, or overloaded, and none of those states carry information about whether the move is safe. Treating them as approval converts an availability failure into an execution failure. The tripwire refuses the conversion.

The cost is real and worth stating plainly: a system that fails closed on silence will stall work that a present operator would have released. That is the trade being made deliberately. A halt is reversible on the next cycle. The action it prevents may not be.

**On recycle.** A move returning to the cycle does not return unchanged. The trip is compressed into a retrievable kernel — the minimum description of what tripped and under what conditions — and repetition is shed, so a near-identical trip on the next pass resolves against the stored kernel instead of re-consuming the operator's attention from zero. The kernels are written back into the pattern set the heads score against, not only into an audit log. An arbitration layer that logs its halts and learns nothing from them will surface the same halt indefinitely and train the operator to clear it reflexively, which returns the system to fail-open by human habit rather than by design.

---

## 5. Banding and the dissent record

**Bands.**

| Verdict | Band | Behavior |
|---|---|---|
| ≥ 0.70 | Clear | Execute, log |
| 0.35 – 0.70 | Contested | Tripwire per section 4 |
| < 0.35 | Halt | Halt, escalate, no countdown |

**Floor.** Any single `NEG ≥ 0.85` halts regardless of verdict. Case B halts on the floor as well as on the band; either condition alone is sufficient. The floor exists so that an unusually strong positive case cannot arithmetically outrun a catastrophic reading.

**Dissent record.** A halt that does not name its source is not auditable. Each halt writes:

- the head that produced `neg_worst`
- whether the floor tripped, and at what value
- the operator action taken, or the absence of one
- the snapshot reference

Attribution is the point. "The system halted" is not a reviewable claim. "The tactician constructed a 0.91 downside on this input, the floor tripped, the operator did not respond inside the window, and the move recycled" is.

---

## 6. Implementation status

Stating this split explicitly because the difference matters to anyone evaluating the design.

**Shipped (v0.1.0):**
- Three-head POS/NEG/NEUT scoring
- Minimax verdict, worst-case dominant
- Per-head weights, operator-configurable
- Versioned decision chain — replay and rollback
- CLI and HTTP surfaces, plugin system

**Designed, not yet shipped:**
- Band thresholds at the stated values
- The `NEG ≥ 0.85` floor
- Neutral-channel tripwire: halt / snapshot / countdown / recycle
- Kernel distillation and write-back into the pattern set
- Named-dissent ledger fields

**Known gap.** `NEG` currently scores severity without an irreversibility term. A recoverable 0.80 and an unrecoverable 0.80 arbitrate identically, which is tolerable for software-only execution surfaces and is not tolerable for anything that moves physical hardware. Irreversibility belongs as a multiplier on `neg_worst`, not as a separate band. It is the next thing I intend to be wrong about in public.

---

## 7. Scope

This document covers the arbitration layer only. Deployment topology, host configuration, credential handling, plugin permissions and runtime data are deliberately excluded. Numbers in section 3 are illustrative of the scoring shape, not captured from a production run.

Questions and adversarial readings welcome — particularly on section 4. The fail-closed default is the load-bearing claim, and it is the one most likely to be wrong under operating conditions I have not hit yet.
