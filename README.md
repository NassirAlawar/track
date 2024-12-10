As always, use at your own risk.

# Track

Track should be loaded on all characters.
Track has two modes of operation `ipc` and `follow`.

Track is in `ipc` mode if the person to follow is the `leader` which needs to be set in `track.lua` (`globals.leader`).
In `ipc` mode the leader sends their position to other characters which helps to avoid characters getting stuck around walls due to lag.
In `follow` mode, where a character is not following the leader, track will fall back to tracking based on target position. This is more susceptible to lag.

# Commands

* `//track zone` - This will cause the character to run whatever direction they're facing. Can crash if a character is in the middle of zoning and the command is issued via send.
* `//track stop` - The character will stop following
* `//track t <name of character>` - This will follow the character specified. If the character is the `leader` then `ipc` mode is used. (ex: `//track t Geno`)