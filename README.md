# NCAE 2025

Some scripts for NCAE 2025. WGU Team 1.

# What is this? (post competition rundown)
This is a homebrewed poll-based logging solution built entirely with bash scripts. It was intended for rapid deployment during the [NCAE 2025 Competition](https://www.ncaecybergames.org). Then, on game day, they gave us access to a SIEM. So we didn't really end up using it.

I wrote a poll-based solution to keep all Private keys on an out-of-scope endpoint. This central endpoint would poll our other in-scope hosts using `ssh` with pre-configured private keys (public keys were added to authorized_keys on each endpoint). Logs were retrieved via the secure encrypted `ssh` connection. 

A terminal-based HUD was built to aggregate logs and provide notifications of potential compromise. `systemd` services were written to automate all processes without any of the security vulnerabilities associated with `cron`.

Secure patterns were utilized wherever reasonably possible.
