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
// published tree, absolute URLs, and in-page anchors are left as they are.
// Fenced code blocks are not touched.
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

let files = 0;
let links = 0;
for (const rel of fs.readdirSync(dir, {recursive: true})) {
  if (!/\.mdx?$/.test(rel)) continue;
  const fileRel = rel.split(path.sep).join('/');
  const file = path.join(dir, rel);
  const parts = fs.readFileSync(file, 'utf8').split(/(^(?:```|~~~)[^\n]*\n[\s\S]*?^(?:```|~~~)[ \t]*$)/m);
  let changed = false;
  for (let i = 0; i < parts.length; i += 2) {
    parts[i] = parts[i].replace(LINK, (m, open, target, close) => {
      const next = rewriteTarget(fileRel, target);
      if (next === target) return m;
      changed = true;
      links++;
      return open + next + close;
    });
  }
  if (changed) {
    fs.writeFileSync(file, parts.join(''));
    files++;
  }
}
console.log(`==> rewrote ${links} link(s) that leave ${subdir}/ in ${files} file(s) to ${base}.`);
