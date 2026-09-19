import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { humation1 } from '@humation/assets-humation-1';
import { createAvatar } from '@humation/core';

const avatarCount = 24;
const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const outputDirectory = resolve(
  scriptDirectory,
  '../../assets/images/avatars/humation',
);

const palettes = [
  {
    hair: '#3D2B1F',
    clothes: '#16A34A',
    bottom: '#166534',
    skin: '#F3C6A5',
    stroke: '#17201A',
    background: '#DCFCE7',
  },
  {
    hair: '#171717',
    clothes: '#2563EB',
    bottom: '#1E3A8A',
    skin: '#D99B73',
    stroke: '#17201A',
    background: '#DBEAFE',
  },
  {
    hair: '#7C3F21',
    clothes: '#DB2777',
    bottom: '#831843',
    skin: '#FFD6B8',
    stroke: '#2B1B18',
    background: '#FCE7F3',
  },
  {
    hair: '#2F241F',
    clothes: '#7C3AED',
    bottom: '#4C1D95',
    skin: '#8D5524',
    stroke: '#1F1726',
    background: '#EDE9FE',
  },
  {
    hair: '#C47A3A',
    clothes: '#EA580C',
    bottom: '#9A3412',
    skin: '#F1C27D',
    stroke: '#2C1B12',
    background: '#FFEDD5',
  },
  {
    hair: '#352218',
    clothes: '#0891B2',
    bottom: '#155E75',
    skin: '#C68642',
    stroke: '#13262A',
    background: '#CFFAFE',
  },
];

function materializeColors(svg, colors) {
  let output = svg;
  for (const [slot, color] of Object.entries(colors)) {
    const variable = new RegExp(
      `var\\(--hm-${slot},\\s*#[0-9a-fA-F]{6}\\)`,
      'g',
    );
    output = output.replace(variable, color);
  }
  return output.replace(/ style="--hm-[^"]+"/, '');
}

await mkdir(outputDirectory, { recursive: true });

let avatarIndex = 0;
let seedIndex = 1;
while (avatarIndex < avatarCount) {
  const palette = palettes[avatarIndex % palettes.length];
  const avatar = createAvatar(humation1, {
    seed: `riksa-community-avatar-${seedIndex}`,
    colors: palette,
    background: palette.background,
  });
  const svg = materializeColors(avatar.toString(), palette);
  seedIndex += 1;

  // flutter_svg intentionally ignores embedded CSS <style> blocks. Skip
  // combinations containing Illustrator class styles so every bundled avatar
  // renders consistently on Android, iOS, and web.
  if (svg.includes('<style')) continue;

  const number = String(avatarIndex + 1).padStart(2, '0');
  await writeFile(resolve(outputDirectory, `avatar-${number}.svg`), svg);
  avatarIndex += 1;
}

console.log(`Generated ${avatarCount} Humation avatars in ${outputDirectory}`);
