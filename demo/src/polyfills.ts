// @ts-nocheck
import { Buffer } from 'buffer';
window.Buffer = Buffer;

import * as process from 'process';
window.process = process;

if (import.meta.env.DEV) {
  window.global = window;
}
