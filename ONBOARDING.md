# Welcome to Team Relay

## How We Use Claude

Based on chandresh sankhala's usage over the last 30 days:

Work Type Breakdown:
  Build Feature    █████████████░░░░░░░  67%
  Improve Quality  ███████░░░░░░░░░░░░░  33%

Top Skills & Commands:
  /goal                   ████████████████████  4x/month
  /skills                 ███████████████░░░░░  3x/month
  /plugin                 ██████████░░░░░░░░░░  2x/month
  /team-onboarding        ██████████░░░░░░░░░░  2x/month
  /qa                     █████░░░░░░░░░░░░░░░  1x/month
  /debug                  █████░░░░░░░░░░░░░░░  1x/month
  /ponytail:ponytail      █████░░░░░░░░░░░░░░░  1x/month
  /ponytail:ponytail-audit █████░░░░░░░░░░░░░░░  1x/month
  /skillify               █████░░░░░░░░░░░░░░░  1x/month
  /doctor                 █████░░░░░░░░░░░░░░░  1x/month
  /compact                █████░░░░░░░░░░░░░░░  1x/month
  /fast                   █████░░░░░░░░░░░░░░░  1x/month
  /ide                    █████░░░░░░░░░░░░░░░  1x/month
  /model                  █████░░░░░░░░░░░░░░░  1x/month

Top MCP Servers:
  _None used in this window_

## Your Setup Checklist

### Codebases
- [ ] dakshai — https://github.com/chandresh-ship-it/dakshai
- [ ] chatwoot (newrelay) — the main working repo; Relay design system work lives on `feat/relay-ui-components`

### MCP Servers to Activate
- [ ] _None currently in use — nothing to set up here yet_

### Skills to Know About
- [ ] /goal — set the objective for a session and let Claude keep working until it's met; the most-used command here
- [ ] /qa — systematically QA a feature in the running app and fix what it finds
- [ ] /debug — work a bug down to root cause instead of patching the symptom
- [ ] /ponytail:ponytail — forces the laziest solution that actually works; matches this repo's "MVP focus, least code change" rule
- [ ] /ponytail:ponytail-audit — one-shot scan for over-engineering; returns a ranked list of what to delete
- [ ] /skills — browse what skills are installed and available
- [ ] /plugin, /skillify — install plugin bundles, and turn a flow that worked into a reusable skill
- [ ] /compact — compress a long conversation without losing the thread
- [ ] /fast — faster Opus output for quick iterations
- [ ] /ide — connect Claude Code to your editor
- [ ] /doctor — check your Claude Code install when something looks off

## Team Tips

_TODO_

## Get Started

Starter task: **Contacts UI parity + functionality testing.** Check out
`feat/relay-ui-components`, compare the Contacts screens against the NewRelay-UI
reference design, and bring them in line — then QA the result end to end and
write up bugs and improvements.

Two things worth knowing before you start:
- New and redesigned dashboard UI uses the Relay design system in
  `app/javascript/dashboard/components-next/relay/` — see `DESIGN.md` and
  `TOKENS.md` there. Don't add new `woot-*` / `WootButton` / `WootModal` usages.
- Tailwind utilities and semantic color tokens only. No custom CSS, no scoped
  CSS, no inline styles, no hardcoded hex.

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
