# CodableToTypeScript

Generate typescript code for typing JSON from Swift Codable.

# Live Demo

https://omochi.github.io/CodableToTypeScript/

This demo site runs CodableToTypeScript on your browser locally by [swiftwasm](https://swiftwasm.org) technology.
Its also built by CodableToTypeScript, and [WasmCallableKit](https://github.com/sidepelican/WasmCallableKit).
See [source code](demo).

# Usage and Example

See [test cases](Tests/CodableToTypeScriptTests/Generate/GenerateExampleTests.swift).
 
# Development guide

## Requirements

It needs nodejs and typescript for testing.

```
$ brew install node
$ npm install -g typescript
```

See below for details.

## Testing

Test cases generate typescript codes and build them to check generated codes validity.
For invocating typescript compiler, it uses `$ npx tsc`.
So you need to install typescript on host globally.

You can skip this step by defining `SKIP_TSC` environment variable.
