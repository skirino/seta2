Prerequisites for macOS
- (brew) vala
- (brew) gtk+3
- (brew) vte3
- Brew-installed vte's vapi file seems broken (spawn_async's signature is not matching the C counterpart).
  In addition to the brew package, we also need to clone the vte's repository from gitlab.
- Compiled binary of <https://github.com/minoki/InputSourceSelector> must be on `PATH`

TODOs:
- select appropriate token in terminal by double-clicking (set word_char_exceptions)
- search dialog in terminal
