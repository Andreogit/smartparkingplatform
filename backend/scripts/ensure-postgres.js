/**
 * Ensures PostgreSQL is reachable before Nest starts (local dev).
 * If port is closed, tries: docker compose up -d postgres (repo root).
 */
const net = require('node:net');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const DEFAULT_HOST = '127.0.0.1';
const DEFAULT_PORT = 5432;
const WAIT_MS = 30_000;
const POLL_MS = 500;

function parseDatabaseTarget() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    return { host: DEFAULT_HOST, port: DEFAULT_PORT };
  }
  try {
    const parsed = new URL(url);
    return {
      host: parsed.hostname || DEFAULT_HOST,
      port: parsed.port ? Number(parsed.port) : DEFAULT_PORT,
    };
  } catch {
    return { host: DEFAULT_HOST, port: DEFAULT_PORT };
  }
}

function canConnect(host, port) {
  return new Promise((resolve) => {
    const socket = net.connect({ host, port, timeout: 1500 }, () => {
      socket.end();
      resolve(true);
    });
    socket.on('error', () => resolve(false));
    socket.on('timeout', () => {
      socket.destroy();
      resolve(false);
    });
  });
}

async function waitForPort(host, port) {
  const deadline = Date.now() + WAIT_MS;
  while (Date.now() < deadline) {
    if (await canConnect(host, port)) {
      return true;
    }
    await new Promise((r) => setTimeout(r, POLL_MS));
  }
  return false;
}

function startDockerPostgres() {
  const repoRoot = path.resolve(__dirname, '../..');
  const composeFile = path.join(repoRoot, 'docker-compose.yml');
  console.log('[bkr] Starting PostgreSQL: docker compose up -d postgres');
  const result = spawnSync(
    'docker',
    ['compose', '-f', composeFile, 'up', '-d', 'postgres'],
    { cwd: repoRoot, stdio: 'inherit', env: process.env },
  );
  return result.status === 0;
}

async function main() {
  const { host, port } = parseDatabaseTarget();

  if (host !== '127.0.0.1' && host !== 'localhost') {
    // Remote DB — do not try to start Docker locally.
    if (await canConnect(host, port)) {
      return;
    }
    console.error(
      `[bkr] Cannot reach PostgreSQL at ${host}:${port}. Check DATABASE_URL and network.`,
    );
    process.exit(1);
  }

  if (await canConnect(host, port)) {
    return;
  }

  if (!startDockerPostgres()) {
    console.error(
      '[bkr] PostgreSQL is not running and Docker failed to start it.\n' +
        '  From repo root: docker compose up -d postgres\n' +
        '  Or start your own Postgres on 127.0.0.1:5432',
    );
    process.exit(1);
  }

  if (!(await waitForPort(host, port))) {
    console.error(
      `[bkr] PostgreSQL still not reachable at ${host}:${port} after ${WAIT_MS / 1000}s.`,
    );
    process.exit(1);
  }

  console.log(`[bkr] PostgreSQL ready at ${host}:${port}`);
}

main().catch((err) => {
  console.error('[bkr] ensure-postgres failed:', err);
  process.exit(1);
});
