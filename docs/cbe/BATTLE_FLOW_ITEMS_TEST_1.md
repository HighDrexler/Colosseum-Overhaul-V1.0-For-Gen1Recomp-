Battle Flow and Doubles Items Test 1

Install the CBE ZIP in place of the prior CBE ZIP. The paired UI ZIP enables Bag selection and is based on the available 2.4.0-doubles-test.3 UI. If your UI has newer work, merge doubles-ui-items-test-1.patch instead; see Doubles-item-API.md. Keep your existing source import/cache. No source rebuild is required by this update.

Automatic flow
AUTO BATTLE FLOW is ON by default in CBE settings. Finished native Gen I/II battle messages and continuation pages receive an acknowledgement after 0.8-3 real seconds, scaled by text length. Native text reveal, move animation, HP drain and sound gates remain in place. The input edge exists only for the completed-message update and is restored even on an error. Move selection, targets, switches, replacements, yes/no choices, stats boxes and move learning remain manual. A/B can still advance text normally. OFF restores manual message acknowledgement; doubles presentation events then require acknowledgement after their animation/minimum hold.

Doubles already had automatic event timing. This update adds readable text holds and connects the same preference; all presentationPending holds remain unskippable. Tests exercise an entire item/partner-move turn with no A/B presses, stopping at the next command menu. Native post-battle message handoffs use the new automatic flow, while interactive reward/learning screens remain manual.

Doubles items
Bag now supports healing medicines, status cures, revives, Ether/Elixer-family PP restoration and native battle stat items. Gen II includes its relevant berries and bitter medicines. Target either active ally or a bench member where allowed; stat items target an active ally. PP items request a move when needed. Native effect code supplies generation-specific amounts and conditions. One item takes one Pokemon's action, leaving the partner's action available. Stock is reserved during selection and consumed only on successful execution; cancel releases reservations. Items resolve ahead of moves, and no separate singles turn is run. HP/status presentation uses the existing doubles event queue. The encounter-abort path restores inventory as well as the original party.

Preserved
Previous MoveFX identifier and off-screen-anchor fixes are retained. MoveFX rendering, camera, trainer, ball release and hit-reaction code is unchanged in this build.

Validation
All CBE Lua parses; 30 focused suites pass. Paired presentation/UI tests pass 382 assertions. Native Gen I/II integration tests pass 194 assertions covering real item arithmetic, target identity, inventory reservations/cancellation, no-effect refusal, PP mirrors, battle stages, automatic native messages, automatic doubles turns and manual command boundaries. Graphics are stubbed in native integration tests. This is not a live playthrough of the full installed mod stack.

Limits
Balls cannot capture opponents in these trainer doubles. Field items, TMs, evolution items and permanent stat/PP boosters are not offered. Trainer AI item selection is unchanged. New item-specific 3D effects are not added; item messages and HP/status updates use existing presentation.
