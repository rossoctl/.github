#!/usr/bin/env node
// rewrite-repo-links.mjs: point relative Markdown links that leave a synced
// docs tree at the file on GitHub instead.
//
//   node rewrite-repo-links.mjs <dir> <subdir> <github-blob-base> [excluded...]
//
// <dir> holds a copy of <subdir>/ of the source repository. A link such as
// ](../../deploy/sbx/README.md) in <dir>/guides/x.md resolves to deploy/sbx/README.md
// in the repository, outside <subdir>/, so it becomes
// ](<github-blob-base>/deploy/sbx/README.md). So does a link into an [excluded]
// entry of <subdir>/ (a folder or file the sync left out). Links inside the
// published tree, absolute URLs, and in-page anchors are left as they are, and so
// is code (see FENCE below).
import fs from 'node:fs';
import path from 'node:path';

const [dir, subdir, base, ...excluded] = process.argv.slice(2);
if (!dir || !subdir || !base) {
  console.error('usage: rewrite-repo-links.mjs <dir> <subdir> <github-blob-base> [excluded...]');
  process.exit(2);
}

const LINK = /(\]\()([^)\s]+)((?:\s+"[^"]*")?\))/g;

function rewriteTarget(fileRel, target) {
  if (/^(?:[a-z][a-z0-9+.-]*:|#|\/)/i.test(target)) return target;
  const hash = target.indexOf('#');
  const p = hash === -1 ? target : target.slice(0, hash);
  const anchor = hash === -1 ? '' : target.slice(hash);
  if (!p) return target;
  const repoPath = path.posix.normalize(path.posix.join(subdir, path.posix.dirname(fileRel), p));
  const inTree = repoPath === subdir || repoPath.startsWith(subdir + '/');
  const top = inTree ? repoPath.slice(subdir.length + 1).split('/')[0] : '';
  if (inTree && !excluded.includes(top)) return target;
  if (repoPath.startsWith('../')) return target; // leaves the repository: leave it alone
  return `${base}/${repoPath}${anchor}`;
}

// Code is left alone: fenced blocks (``` or ~~~, any length of 3 or more, at any indent, so
// fences inside list items count too; closed only by a fence of the same character, at least
// as long, with nothing after it, as CommonMark has it; an unclosed fence runs to the end of
// the file) and inline code spans (a run of N backticks up to the next run of exactly N).
const FENCE = /^\s*(`{3,}|~{3,})(.*)$/;

function rewriteProse(fileRel, line, onChange) {
  let out = '';
  let i = 0;
  while (i < line.length) {
    const tick = line.indexOf('`', i);
    const prose = tick === -1 ? line.slice(i) : line.slice(i, tick);
    out += prose.replace(LINK, (m, open, target, close) => {
      const next = rewriteTarget(fileRel, target);
      if (next === target) return m;
      onChange();
      return open + next + close;
    });
    if (tick === -1) break;
    const run = /^`+/.exec(line.slice(tick))[0];
    const closeAt = line.slice(tick + run.length).search(new RegExp(`(?<!\`)${run}(?!\`)`));
    if (closeAt === -1) {
      // No closing run on this line: the backticks are literal text.
      out += run;
      i = tick + run.length;
      continue;
    }
    const end = tick + run.length + closeAt + run.length;
    out += line.slice(tick, end);
    i = end;
  }
  return out;
}

function rewriteFile(fileRel, text, onChange = () => {}) {
  const lines = text.split('\n');
  let fence = null; // the opening fence's character and length while inside a block
  for (let n = 0; n < lines.length; n++) {
    const m = FENCE.exec(lines[n]);
    if (fence) {
      if (m && m[1][0] === fence[0] && m[1].length >= fence.length && m[2].trim() === '') {
        fence = null;
      }
      continue;
    }
    // A backtick fence's info string may not contain a backtick (CommonMark 4.5).
    if (m && !(m[1][0] === '`' && m[2].includes('`'))) {
      fence = m[1];
      continue;
    }
    lines[n] = rewriteProse(fileRel, lines[n], onChange);
  }
  return lines.join('\n');
}

let files = 0;
let links = 0;
for (const rel of fs.readdirSync(dir, {recursive: true})) {
  if (!/\.mdx?$/.test(rel)) continue;
  const fileRel = rel.split(path.sep).join('/');
  const file = path.join(dir, rel);
  let changed = 0;
  const text = rewriteFile(fileRel, fs.readFileSync(file, 'utf8'), () => changed++);
  if (changed) {
    fs.writeFileSync(file, text);
    files++;
    links += changed;
  }
}
console.log(`==> rewrote ${links} link(s) that leave ${subdir}/ in ${files} file(s) to ${base}.`);
