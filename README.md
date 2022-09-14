Prerequisites for macOS
- (brew) vala
- (brew) vte3
- (brew) gtk+3
  - Older version of gtk+3 is needed; 3.24.33 is known to work.
    - Newer versions suffer from non-working input method support:
      - `\` character is interpreted as `¥`.
      - japanese characters cannot be input.
    - To setup:
      - Uninstall later version of gtk+3; it could be installed alongside vte3.
      - Install the working version:
        - `brew tap-info skirino/taps`
        - `brew extract gtk+3 skirino/taps --version 3.24.33`
        - `brew install skirino/taps/gtk+3@3.24.33`
      - Make a symlink: `/opt/homebrew/opt/gtk+3` -> `/opt/homebrew/opt/gtk+3@3.24.33`
        because vte3 dylib assumes gtk+3 dylib exists at the path without `@3.24.33`.
- Brew-installed vte's vapi file seems broken (spawn_async's signature is not matching the C counterpart).
  In addition to the brew package, we also need to clone the vte's repository from gitlab.
- Compiled binary of <https://github.com/minoki/InputSourceSelector> must be on `PATH`

TODOs:
- select appropriate token in terminal by double-clicking (set word_char_exceptions)
- search dialog in terminal
