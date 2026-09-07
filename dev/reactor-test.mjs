import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const compiler = resolve(process.argv[2] ?? join(root, '_build/default/bin/kanon.exe'));
const scratch = mkdtempSync(join(tmpdir(), 'kanon-reactor-'));
const fixture = name => join(root, 'test/fixtures/reactor', `${name}.kan`);
const run = args => spawnSync(compiler, args, { encoding: 'utf8' });
const exports = ['empty', 'prepend', 'byteHead', 'byteTail',
  'byteLength', 'initialState', 'stateCount', 'stateBytes', 'updateState',
  'increment', 'literalBytes', 'literalEmpty'];
let checks = 0;
const verify = fn => { fn(); checks += 1; };

try {
  const output = join(scratch, 'reactor.wasm');
  const built = run(['build', fixture('reactor-types'), fixture('reactor-functions'),
    fixture('byte-literal-valid'), '-o', output, ...exports.flatMap(name => ['--export', name])]);
  assert.equal(built.status, 0, built.stderr);
  const bytes = readFileSync(output);
  const { instance } = await WebAssembly.instantiate(bytes);
  const e = instance.exports;
  verify(() => assert.deepEqual(Object.keys(e), exports));
  verify(() => assert.equal(WebAssembly.Module.imports(new WebAssembly.Module(bytes)).length, 0));
  verify(() => assert.equal(typeof e.empty(), 'object'));
  verify(() => assert.equal(e.byteLength(e.empty()), 0));
  const list = e.prepend(65, e.prepend(255, e.empty()));
  verify(() => assert.equal(e.byteLength(list), 2));
  verify(() => assert.equal(e.byteHead(list), 65));
  verify(() => assert.equal(e.byteHead(e.byteTail(list)), 255));
  const original = e.initialState();
  const updated = e.updateState(original, 7, list);
  verify(() => assert.equal(e.stateCount(original), 0));
  verify(() => assert.equal(e.stateCount(updated), 7));
  verify(() => assert.equal(e.byteLength(e.stateBytes(updated)), 2));
  verify(() => assert.equal(e.increment(1073741822), 1073741823));
  for (const invalid of [-1, 1073741824, 2147483647, -2147483648]) {
    verify(() => assert.throws(() => e.prepend(invalid, list), WebAssembly.RuntimeError));
  }
  verify(() => assert.throws(() => e.increment(1073741823), WebAssembly.RuntimeError));
  for (const invalid of [null, undefined, {}, [], 0, 'bytes', original]) {
    verify(() => assert.throws(() => e.byteLength(invalid), TypeError));
  }
  verify(() => assert.throws(() => e.stateCount(list), TypeError));
  let literal = e.literalBytes();
  const observed = [];
  while (e.byteLength(literal) !== 0) {
    observed.push(e.byteHead(literal));
    literal = e.byteTail(literal);
  }
  verify(() => assert.deepEqual(observed, [65, 10, 13, 9, 0, 92, 34, 255, 195, 169]));
  verify(() => assert.equal(e.byteLength(e.literalEmpty()), 0));
  for (const name of ['byte-literal-bad-escape', 'byte-literal-bad-hex', 'byte-literal-unterminated']) {
    const failed = run(['check', fixture(name)]);
    verify(() => assert.equal(failed.status, 1, name));
    verify(() => assert.match(failed.stderr, /byte (?:escape|literal)/));
  }
  const duplicate = run(['build', fixture('reactor-types'), '-o', output,
    '--export', 'bytesNil', '--export', 'bytesNil']);
  verify(() => assert.equal(duplicate.status, 2));
  const missing = run(['build', fixture('reactor-types'), '-o', output, '--export', 'missing']);
  verify(() => assert.equal(missing.status, 2));
  const noExport = run(['build', fixture('reactor-types'), '-o', output]);
  verify(() => assert.equal(noExport.status, 64));
  const legacy = run(['emit', join(root, 'test/fixtures/mu-mutual-emit.kan'), '-o', output, '--export', 'main']);
  verify(() => assert.equal(legacy.status, 0, legacy.stderr));
  verify(() => assert.deepEqual(readFileSync(output), readFileSync(join(root, 'test/mu-mutual-emit.wasm'))));
  const { instance: old } = await WebAssembly.instantiate(readFileSync(output));
  verify(() => assert.equal(old.exports.main(), 4));
  process.stdout.write(`reactor: ${checks} checks passed\n`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
