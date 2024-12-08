# urwasm
WebAssembly interpreter suite for Urbit

Continuation of my work on [UWasm](https://github.com/Quodss/wasm-hackathon). Copy the files from `desk` directory to a new Urbit desk and commit them. Run tests with:
```
-test /=wasm=/tests ~
```
## Running your own wasm modules

Beginning with a simple fibonacci example:

0. (optional) download rust `$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
1. `$ cd /rust`
2. `$ mkdir my_rust`
3. `$ cd my_rust`
4. `$ cargo init --lib .`
5. add `wasm-bindgen = "0.2"` to `Cargo.toml`
6. add `crate-type = ["cdylib"]` to a new section `[lib]` in `Cargo.toml`
7. rename `name` in `Cargo.toml` to `simple-fib`
8. `$ rustup target add wasm32-unknown-unknown`
9. `$ cargo build --release --target wasm32-unknown-unknown`
10. in a new terminal and location download urbit cli `https://docs.urbit.org/manual/getting-started/self-hosted/cli#2-install-urbit`
11. run `$ ./urbit -F zod` to run a ship
12. in your ship terminal `> |new-desk %wasm`
13. in your ship terminal `> |mount %wasm`
14. copy all of the working desk to your fakezod from earth filesystem `$ cp -r urwasm/desk/* zod/wasm/.`
15. copy wasm file to desk from original terminal, from `my_rust` folder, run `$ cp /target/wasm32-unknown-unknown/simple_fib.wasm /local-path-to-ship/zod/wasm/tests/`
16. in your ship terminal `> |commit %wasm`
17. add the following code to a new test file called `test.hoon` in `tests` folder:

```hoon
/+  *test
/+  *wasm-runner-engine
/*  fib-rust   %wasm  /tests/simple_fib/wasm
::
|%
++  test-rust
  ::  Test a module obtained from wasm-pack utility in Rust
  ::
  %+  expect-eq
    !>  `(list coin-wasm:wasm-sur)`~[[type=%i32 n=102.334.155]]
    !>
    =<  -  %-  wasm-need:engine
    %^  invoke:engine  'fib'  ~[[%i32 40]]
    +:(wasm-need:engine (prep:engine (main:parser fib-rust) ~))
--
```
18. run tests on mars on your ship `> -test /=wasm=/tests/test ~`

Then, to edit the rust code and rerun complete the steps: 9, 15, 16, 18

note: if you try to run with Wasmtime, the wasm can't be invoked

## State of the project:

- [X] Complete Wasm interpreter specification in Hoon
- [X] Parsing of both binary and text Wasm file formats (the latter is done via Wasm calls, so it's slow without jets)
- [X] Stage 1 complete! Jetted execution of Wasm without state preservation
  - suitable for parsers, compession algorithms, etc

Next:
- [X] Language for Invocation of Assembly (Lia) specification
- [X] Lia monad in Hoon:
- [X] Jet of Lia monad reducer:
- [ ] Operationalization:
  - [ ] Caching of Lia state
  - [ ] Unit tests


