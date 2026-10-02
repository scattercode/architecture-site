"""Load the platform's machine-readable descriptions for the generated chapters.

The JSON extracts in data/ are read once into plain Python objects. Chapters
import this module in a Python cell and print Markdown (tables, lists, SVG)
with `#| output: asis`, so the same cell serves the website, the PDF and the
Word output.

Keep the JSON shape in one place: if the producing pipeline changes its
output, change `load_environments` here and the chapters carry on working.
"""
from __future__ import annotations

import html
import json
from dataclasses import dataclass, field
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"


@dataclass
class Workspace:
    name: str
    catalog: str
    compute: str = ""
    purpose: str = ""


@dataclass
class Environment:
    name: str
    region: str
    subscription: str
    description: str = ""
    storage: list[str] = field(default_factory=list)
    workspaces: list[Workspace] = field(default_factory=list)


ENVIRONMENT_ORDER = ["dev", "ppr", "prd"]


def load_environments(data_dir: Path = DATA_DIR) -> list[Environment]:
    """Read data/environments/*.json into Environment objects, in release order."""
    envs = []
    for path in sorted((data_dir / "environments").glob("*.json")):
        raw = json.loads(path.read_text())
        envs.append(
            Environment(
                name=raw["name"],
                region=raw.get("region", ""),
                subscription=raw.get("subscription", ""),
                description=raw.get("description", ""),
                storage=list(raw.get("storage", [])),
                workspaces=[Workspace(**w) for w in raw.get("workspaces", [])],
            )
        )
    order = {name: i for i, name in enumerate(ENVIRONMENT_ORDER)}
    return sorted(envs, key=lambda e: (order.get(e.name, len(order)), e.name))


def md_table(headers: list[str], rows: list[list[str]],
             caption: str | None = None, label: str | None = None) -> str:
    """A pipe table. With a caption (and optional label) it becomes a numbered,
    cross-referenceable Quarto table."""
    cell = lambda v: str(v).replace("|", "\\|")
    lines = ["| " + " | ".join(cell(h) for h in headers) + " |",
             "|" + "|".join("---" for _ in headers) + "|"]
    lines += ["| " + " | ".join(cell(c) for c in row) + " |" for row in rows]
    if caption:
        lines.append("")
        lines.append(f": {caption}" + (f" {{#{label}}}" if label else ""))
    return "\n".join(lines) + "\n"


def write_asset(relative_path: str, content: str) -> Path:
    """Write a generated file under the project root. Paths are relative to
    the project root, which is where executed cells run (`execute-dir:
    project` in _quarto.yml)."""
    path = DATA_DIR.parent / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


def write_diagram(relative_stem: str, svg: str) -> str:
    """Write a generated SVG diagram plus the PDF and PNG copies the other
    formats use, and return the extension-less path to put in the image
    reference: `![caption](assets/name){#fig-name}`.

    The house formats set `default-image-extension` (svg for the website,
    pdf for PDF, png for Word), so one reference serves all three without
    relying on Quarto converting SVG at render time — which fails for
    images produced by a code cell when a document renders to several
    formats in one go. Needs `rsvg-convert` (package librsvg2-bin).
    """
    import shutil
    import subprocess

    svg_path = write_asset(relative_stem + ".svg", svg)
    if shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-f", "pdf", str(svg_path),
                        "-o", str(svg_path.with_suffix(".pdf"))], check=True)
        subprocess.run(["rsvg-convert", "-f", "png", "-z", "2", str(svg_path),
                        "-o", str(svg_path.with_suffix(".png"))], check=True)
    else:
        print("<!-- rsvg-convert not found: PDF and PNG copies of "
              f"{relative_stem} were not refreshed -->")
    # Relative to the document, which sits one level below the project root.
    return str(Path(relative_stem).relative_to(Path(relative_stem).parts[0]))


# --- Diagrams --------------------------------------------------------------
# House palette, matching the hand-drawn SVGs and the quarto-house extension.
TEALS = ["#367E8D", "#2A6372", "#1F4A58", "#16323E"]
INK, SLATE, CREAM = "#14232A", "#5D7079", "#FAFAF7"
FONT = "-apple-system, 'Helvetica Neue', Arial, sans-serif"


def environments_svg(envs: list[Environment]) -> str:
    """One box per environment, three workspace boxes inside each."""
    box_w, gap, pad = 300, 40, 24
    width = pad * 2 + len(envs) * box_w + (len(envs) - 1) * gap
    height = 290
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'width="{width}" height="{height}" font-family="{FONT}">',
        f'<rect width="{width}" height="{height}" fill="{CREAM}"/>',
        f'<text x="{width/2}" y="34" text-anchor="middle" font-family="Georgia, serif" '
        f'font-size="22" fill="{INK}">Environments and workspaces</text>',
        f'<text x="{width/2}" y="54" text-anchor="middle" font-size="12" fill="{SLATE}">'
        f'Generated from data/environments — {len(envs)} environments, '
        f'{sum(len(e.workspaces) for e in envs)} workspaces</text>',
    ]
    for i, env in enumerate(envs):
        x = pad + i * (box_w + gap)
        y = 76
        parts.append(f'<rect x="{x}" y="{y}" width="{box_w}" height="190" rx="10" '
                     f'fill="{CREAM}" stroke="{SLATE}" stroke-width="1.5"/>')
        parts.append(f'<text x="{x + 16}" y="{y + 28}" font-size="16" font-weight="600" '
                     f'fill="{INK}">{html.escape(env.name)}</text>')
        parts.append(f'<text x="{x + box_w - 16}" y="{y + 28}" text-anchor="end" font-size="11" '
                     f'fill="{SLATE}">{html.escape(env.subscription)} · {html.escape(env.region)}</text>')
        for j, ws in enumerate(env.workspaces):
            wy = y + 48 + j * 44
            parts.append(f'<rect x="{x + 16}" y="{wy}" width="{box_w - 32}" height="36" rx="6" '
                         f'fill="{TEALS[min(j, len(TEALS) - 1)]}"/>')
            parts.append(f'<text x="{x + 30}" y="{wy + 23}" font-size="13" fill="#fff" '
                         f'font-weight="600">{html.escape(ws.name)}</text>')
            parts.append(f'<text x="{x + box_w - 30}" y="{wy + 23}" text-anchor="end" font-size="11" '
                         f'fill="#fff">{html.escape(ws.catalog)}</text>')
        if i < len(envs) - 1:
            ax = x + box_w
            parts.append(f'<line x1="{ax + 4}" y1="{y + 95}" x2="{ax + gap - 4}" y2="{y + 95}" '
                         f'stroke="{SLATE}" stroke-width="1.6" marker-end="url(#arrow)"/>')
    parts.insert(1, f'<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" '
                    f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
                    f'<path d="M0,0 L10,5 L0,10 z" fill="{SLATE}"/></marker></defs>')
    parts.append(f'<text x="{width/2}" y="{height - 10}" text-anchor="middle" font-family="Georgia, serif" '
                 f'font-style="italic" font-size="12" fill="{SLATE}">Releases move left to right.</text>')
    parts.append("</svg>")
    return "\n".join(parts)
