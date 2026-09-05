# Headers Option

Uses the custom EBNF grammar defined in [ebnf.md](ebnf.md).

Controls the visibility & format of the headers row.

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```ebnf
headers-option = "--no-headers" | "--headers" [ "=" <headers-format> ] (* default: "--no-headers" *)
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

`<headers-format>` is reserved for future implementation. It will format color,
bold, underlined, etc.
