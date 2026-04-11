# MooseFS Client Admin

Custom MooseFS client image that bundles all troubleshooting tools in a single container:

- **moosefs-client** tools: `mfsfileinfo`, `mfsfilerepair`, `mfscheckfile`, `mfsfilepaths`, `mfsdirinfo`, etc.
- **moosefs-cli** (`mfscli`): queries the MooseFS master for cluster status, missing chunks, and more
- **ttyd**: web-based terminal accessible via browser (it is strongly recommended to enable authentication, e.g. via a custom reverse-proxy or via a SecurityPolicy provided by Envoy Proxy's implementation of the Kubernetes Gateway API)

## Troubleshooting Guide

### 1. Cluster Health Overview

Get a full summary of cluster state including chunk health, missing files, and memory usage:

```bash
mfscli -H mfsmaster -SIN
```

For JSON output (useful for scripting):

```bash
mfscli -H mfsmaster -SIN -j
```

### 2. Missing Chunks

Missing chunks indicate data that cannot be read because no copies exist in the cluster. With goal=1 (no replication), this means permanent data loss for the affected portion of the file.

#### Identify affected files

Query the master directly — this is instant regardless of filesystem size:

```bash
mfscli -H mfsmaster -SMF
```

JSON output for easier parsing:

```bash
mfscli -H mfsmaster -SMF -j
```

The output lists each missing chunk with the file path, inode, chunk index, chunk ID, and type (e.g. "No copy").

#### Inspect the affected file

```bash
mfsfileinfo /mnt/moosefs/<path>
```

Shows every chunk of the file, its version, which chunkserver holds it, and whether it is available. Look for chunks marked "missing data copies / data parts - unrecoverable".

#### Verify chunk counts

```bash
mfscheckfile /mnt/moosefs/<path>
```

Prints a summary of how many chunks exist and how many copies of each.

#### Repair (zero-fill missing chunks)

**Warning:** This permanently replaces missing chunks with zeros. Only use this when:

- The file exists in an external backup and you want to make the filesystem consistent
- The file is expendable (e.g. a log file)
- You have confirmed there is no way to recover the original chunkserver disk

```bash
mfsfilerepair /mnt/moosefs/<path>
```

Output shows how many chunks were repaired (zero-filled) and how many were erased.

### 3. Undergoal and Endangered Chunks

Chunks below their replication goal or with only one surviving copy:

```bash
mfscli -H mfsmaster -SIC
```

This displays a matrix of chunk states: how many chunks are at each combination of goal vs. actual copy count.

### 4. File-Level Diagnostics

#### Show chunks with problems only

```bash
mfsfileinfo -w /mnt/moosefs/<path>
```

The `-w` flag filters to only show chunks that are missing, have wrong versions, or are invalid.

#### Find all paths to a file (hard links)

```bash
mfsfilepaths /mnt/moosefs/<path>
```

Or by inode number (must be run within the MooseFS mount):

```bash
cd /mnt/moosefs
mfsfilepaths <inode>
```

#### Directory statistics

```bash
mfsdirinfo /mnt/moosefs/<path>
```

Shows total files, directories, chunks, size, and replication status for a directory tree.

### 5. Storage Class Management

#### List storage classes

```bash
mfslistsclass -M /mnt/moosefs
```

#### Check a file's storage class

```bash
mfsgetsclass /mnt/moosefs/<path>
```

#### Set storage class

```bash
mfssetsclass <classname> /mnt/moosefs/<path>
```

### 6. Quota Management

#### Check quotas

```bash
mfsgetquota /mnt/moosefs/<path>
```

#### Set quota

```bash
mfssetquota -s <soft-limit> -h <hard-limit> /mnt/moosefs/<path>
```

---

## mfscli Quick Reference

All commands connect to the master via `mfscli -H mfsmaster <flag>`. Add `-j` for JSON output.

| Flag   | Description                                    |
| ------ | ---------------------------------------------- |
| `-SIN` | Full master info (all sections below combined) |
| `-SMF` | Missing chunks/files                           |
| `-SIC` | Chunk state matrix (goal vs. actual copies)    |
| `-SIM` | Master memory usage                            |
| `-SCS` | Connected chunkservers                         |
| `-SMO` | Active mounts (connected clients)              |

---

## Image Details

- **Base image:** `moosefs/client`
- **Added packages:** `python3` (required by mfscli), `ttyd`
- **Added binary:** `mfscli` (copied from `moosefs/gui`)
- **Entrypoint:** Starts `mfsmount` (background) + `ttyd` on port 7681 (foreground)
- **Registry:** `ghcr.io/mintbluejelly/moosefs-client-admin`
