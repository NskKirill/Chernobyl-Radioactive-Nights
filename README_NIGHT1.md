# Chernobyl: Radioactive Nights — Night 1 prototype

This is a **separate experimental branch**, not a replacement for the existing expedition branch. It restores the originally requested security-room horror game inspired by observation/defense mechanics. It is not yet runtime-verified.

## Implemented as source code

- Server-generated low-poly night office and two sliding security doors.
- Four camera positions, selectable in the client HUD.
- Shared energy supply, consumed over time and faster with closed doors/cameras.
- Subject 06 moves across corridor stages toward one of two doors.
- At the final stage, keeping the correct door closed repels it; leaving the door open results in LOSE.
- Six in-game hours (00:00–06:00) and WIN at 06:00, with restart after WIN/LOSE.
- Server validates action names and argument types; gameplay decisions do not depend on client timer values.

## Studio setup

1. Check out branch `codex/night1-security-horror-prototype` in a **separate working folder**.
2. Install Rojo 7.x, run `rojo serve` in that folder.
3. In Roblox Studio open a **new test place**, connect the Rojo plugin and sync only this branch.
4. Start Play. Confirm that `Workspace.CRN_Night1` contains Office, Doors, Cameras, Corridors and Enemies.
5. Press «НАЧАТЬ НОЧЬ». Verify timer, door controls, cameras, power drain and Subject 06 progression.
6. Wait for enemy at the door: correct closed door should repel it; open door should lead to LOSE.
7. Verify 06:00 WIN, restart and another complete night.

## Important limitations

- **No Roblox Studio execution or Play tests have been performed** for this branch.
- The world is a blockout, not a final art pass; Subject 06 is a placeholder block, not a finished character.
- No audio, jumpscare animation, inventory, persistent progress, monetization, or multiplayer balancing.
- The authored behavior still requires end-to-end Play tests (doors, camera controls, enemy, WIN/LOSE).
- Do not overwrite or publish an existing place before comparing it with the prototype.

## QA acceptance

- [ ] `rojo build default.project.json` succeeds
- [ ] Night starts from READY; doors and cameras respond
- [ ] Power decreases correctly, closed doors consume extra power
- [ ] Subject 06 advances and is repelled by the correct closed door
- [ ] Open door on attack gives LOSE
- [ ] Reaching 06:00 gives WIN
- [ ] Restart works twice in succession without duplicated connections
- [ ] No unexpected errors in Studio Output
