"""Build the spatial-query results table and chart from recorded measurements."""
from pathlib import Path
import json
b=Path(__file__).resolve().parents[1]
r=json.loads((b/'benchmarks/spatial-results.json').read_text())
lines=['| Agents | Layout | Full scan (ms) | Hash + rebuild (ms) | Time reduction | Distance-test reduction |','|---:|---|---:|---:|---:|---:|']
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1000" viewBox="0 0 1400 1000"><rect width="1400" height="1000" fill="#0c1522"/><g font-family="Arial,sans-serif" fill="#e1eaf3"><text x="60" y="65" font-size="32">CPU cost of local agent queries</text><text x="60" y="105" font-size="20">One query per agent. Median of 11 batches; spatial hash includes rebuild.</text><text x="60" y="145" font-size="18">Apple M2 Pro · Godot 4.6.1 · Synthetic static positions · Radius 1.6 m · Cells 5 m</text>']
for i,row in enumerate(r['rows']):
 full=row['full_scan_median_ms'];hashed=row['hash_including_rebuild_median_ms'];reduction=(1-hashed/full)*100;checks=(1-row['hash_distance_tests']/row['full_scan_distance_tests'])*100
 lines.append(f"| {row['agents']:,} | {row['layout']} | {full:.3f} | {hashed:.3f} | {reduction:.1f}% | {checks:.1f}% |")
 y=205+i*113
 svg.append(f'<text x="60" y="{y+25}" font-size="21">{row["agents"]:,} / {row["layout"]}</text>')
 for j,(value,color,label) in enumerate([(full,'#e8ad69','Full scan'),(hashed,'#68d8cb','Hash + rebuild')]):
  yy=y+j*36;w=value/65*780
  svg.append(f'<rect x="285" y="{yy}" width="{max(w,2):.2f}" height="24" fill="{color}"/><text x="{300+w:.2f}" y="{yy+19}" font-size="18">{label}: {value:.3f} ms</text>')
svg+=['<text x="60" y="915" font-size="20">Spread: 72 × 72 m. Dense: 4 × 4 m. Dense queries visit every agent.</text><text x="60" y="952" font-size="18">Scope: query CPU time. Simulation, animation and rendering are excluded.</text></g></svg>']
(b/'media/spatial-savings.svg').write_text('\n'.join(svg))
(b/'benchmarks/results-table.md').write_text('\n'.join(lines)+'\n')
