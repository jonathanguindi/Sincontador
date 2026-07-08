# SinApuestas 🛡️  (English)

A support tool to **quit gambling**: it blocks betting apps and websites on your
**phone (Android and iPhone)** and your **computer**. No VPN. Designed to be
**as hard as possible to turn off** in a moment of weakness, using a password or
passcode ideally held by a trusted person, plus a "commitment period" that
cannot be shortened.

> This is a support tool, not treatment. If gambling is hurting you, combine it
> with real help (see the end).

## What's in this repository

| Folder | For | How it blocks |
|---|---|---|
| `android/` | Android app (Kotlin) | **Accessibility** service + **Device Admin**. Blocks betting apps and sites and defends itself from being uninstalled. |
| `apple/` | iPhone / iPad | Configuration profile with a web filter + native app using **Screen Time / Family Controls**. |
| `desktop/` | Windows / macOS / Linux (Python) | System **hosts** file + a watchdog that repairs it. |
| `blocklists/` | Master lists | Betting domains, packages and keywords, editable. |

## How the "lock" works (on all platforms)

1. You set a **password / passcode** — ideally typed by **someone else** who
   keeps it secret.
2. You choose a **commitment period** (7, 30, 90 days or a year).
3. During that period the block **cannot be turned off**, not even with the
   password. After it, the password is required to remove it.

## Worldwide blocking

Two layers: a curated list of **hundreds of betting sites** across every
continent, plus a **keyword layer** (casino, betting, poker, roulette, slots,
bingo…) that also catches new or unlisted operators. On desktop,
`update_worldwide.py` merges giant public gambling blocklists for maximum
coverage.

## Getting started

- **Android:** open `android/` in Android Studio, install the app, set the
  password, choose the days, and approve the 2 permissions it asks for.
- **iPhone:** follow `apple/README.md` — the recommended path needs no coding.
- **Computer:** go to `desktop/`, follow `desktop/README.md` (one command per OS).

## Honesty about the limits

Without rooting/jailbreaking, nothing is 100% impossible to remove for someone
with admin rights and time. What these tools achieve is **enough friction** to
stop the urge — especially if the password is held by **someone else**, the
commitment period is **long**, and on the computer you use a **non-admin**
account. No app can **close your accounts** at a betting operator — that's done
through **self-exclusion**.

## If gambling is hurting you

- **Self-exclusion** at every operator where you have an account.
- **Payment blocking** for gambling (merchant code MCC 7995): many banks allow it.
- **Gamblers Anonymous**: gamblersanonymous.org

## License

MIT — use it, change it, and share it freely. May it help someone. 💙
