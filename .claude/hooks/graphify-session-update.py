"""
SessionStart hook: incremental graphify update for the jetski project.

Behavior:
  - Reads stdin (hook input) and ignores it (SessionStart hook gets {}).
  - Diffs current files vs the manifest in graphify-out/.
  - No changes  -> silent (no output).
  - Code-only   -> rebuild AST + recluster + overwrite graph.json. Emits
                   systemMessage with the node delta. No LLM cost.
  - Docs/images -> writes graphify-out/.needs_update flag and emits
                   additionalContext telling Claude to run /graphify --update.
  - Errors      -> silent (graphify not installed, no prior graph, etc.).

Output: a single JSON line on stdout that the hook system will interpret.
"""
import json
import sys
from pathlib import Path

# Resolve project root from this file's location: .claude/hooks/<this>.py -> ../..
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# Anything not in this set triggers semantic re-extraction
CODE_EXTS = {
    '.dart', '.py', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.go', '.rs',
    '.java', '.kt', '.kts', '.swift', '.cpp', '.cxx', '.cc', '.c', '.hpp',
    '.h', '.cs', '.rb', '.php', '.scala', '.lua', '.sql', '.toc',
    '.yaml', '.yml',  # config files: AST handles them as data
}


def emit(payload):
    """Write a JSON object to stdout and exit silently."""
    sys.stdout.write(json.dumps(payload))
    sys.stdout.write('\n')
    sys.exit(0)


def silent():
    sys.exit(0)


def main():
    # Drain stdin (the hook always sends JSON, but we ignore it)
    try:
        sys.stdin.read()
    except Exception:
        pass

    graph_path = PROJECT_ROOT / 'graphify-out' / 'graph.json'
    manifest_path = PROJECT_ROOT / 'graphify-out' / 'manifest.json'

    # If no prior graph or manifest, do nothing — first build must be manual via /graphify
    if not graph_path.exists() or not manifest_path.exists():
        silent()

    # Try to import graphify; if missing, silently bail
    try:
        from graphify.detect import detect_incremental, save_manifest
        from graphify.extract import extract
        from graphify.build import build_from_json
        from graphify.cluster import cluster
        from graphify.export import to_json
        from networkx.readwrite import json_graph
    except ImportError:
        silent()

    # Detect changes
    try:
        result = detect_incremental(PROJECT_ROOT)
    except Exception:
        silent()

    new_total = result.get('new_total', 0) or 0
    new_files_dict = result.get('new_files', {})
    deleted = result.get('deleted_files', []) or []
    all_changed = [f for files in new_files_dict.values() for f in files]

    # No changes since last build
    if new_total == 0 and not deleted:
        silent()

    # Branch: code-only vs docs/images
    code_only = all(Path(f).suffix.lower() in CODE_EXTS for f in all_changed)

    if not code_only:
        # Doc/image change requires LLM subagents — write flag + tell Claude
        flag = PROJECT_ROOT / 'graphify-out' / '.needs_update'
        flag.write_text(
            f'{new_total} file(s) changed including docs/images.\n'
            'Run /graphify --update for semantic re-extraction.\n',
            encoding='utf-8',
        )
        sample = ', '.join(Path(f).name for f in all_changed[:3])
        more = f' (+{len(all_changed) - 3} more)' if len(all_changed) > 3 else ''
        emit({
            'systemMessage': f'graphify: {new_total} doc/image change(s) — /graphify --update recommended',
            'hookSpecificOutput': {
                'hookEventName': 'SessionStart',
                'additionalContext': (
                    f'[graphify auto-update] {new_total} file(s) changed since the last graph build, '
                    f'including non-code files ({sample}{more}). The flag '
                    f'`graphify-out/.needs_update` has been written. To get a fresh graph reflecting '
                    f'these changes, run `/graphify --update` (cost: ~150k tokens for full semantic re-extraction, '
                    f'or use the cache subset if available).'
                ),
            },
        })

    # Code-only: AST rebuild without LLM
    try:
        existing = json.loads(graph_path.read_text(encoding='utf-8'))
        G_old = json_graph.node_link_graph(existing, edges='links')
        old_nodes = G_old.number_of_nodes()
        old_edges = G_old.number_of_edges()

        code_paths = [Path(f) for f in all_changed if Path(f).suffix.lower() in CODE_EXTS]
        if code_paths:
            ast = extract(code_paths)
        else:
            ast = {'nodes': [], 'edges': [], 'input_tokens': 0, 'output_tokens': 0}
        G_new = build_from_json({
            'nodes': ast.get('nodes', []),
            'edges': ast.get('edges', []),
            'hyperedges': [],
            'input_tokens': 0,
            'output_tokens': 0,
        })

        # Prune nodes from deleted files
        if deleted:
            stale = [n for n, d in G_old.nodes(data=True) if d.get('source_file') in deleted]
            G_old.remove_nodes_from(stale)

        # Merge new nodes/edges
        G_old.update(G_new)
        communities = cluster(G_old)
        to_json(G_old, communities, str(graph_path), force=True)
        save_manifest(result['files'])

        new_nodes = G_old.number_of_nodes()
        delta = new_nodes - old_nodes
        sign = '+' if delta >= 0 else ''
        emit({
            'systemMessage': (
                f'graphify: code-only update applied '
                f'({old_nodes} -> {new_nodes} nodes, {sign}{delta}), '
                f'{new_total} changed file(s)'
            ),
        })
    except Exception as exc:
        # Don't break the session if rebuild fails — just signal the error softly
        emit({
            'systemMessage': f'graphify: incremental update skipped ({type(exc).__name__})',
        })


if __name__ == '__main__':
    main()
