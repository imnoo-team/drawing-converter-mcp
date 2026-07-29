# Drawing Converter MCP Server

[![Drawing Converter MCP server](https://glama.ai/mcp/servers/imnoo-team/drawing-converter-mcp/badges/score.svg)](https://glama.ai/mcp/servers/imnoo-team/drawing-converter-mcp)

**Convert technical drawings (PDF) and engineering callouts between metric and imperial — from any MCP-enabled AI assistant.**

This [Model Context Protocol](https://modelcontextprotocol.io) server exposes the conversion engine behind [metric-to-imperial-converter.imnoo.com](https://metric-to-imperial-converter.imnoo.com) (by [Imnoo](https://www.imnoo.com)): shop-floor-precision unit conversion for dimensions, ± tolerances, ISO fit classes, threads, surface roughness and weights — including producing a converted copy of a drawing PDF with every value stamped in place.

```
"Convert bracket.pdf to imperial and tell me what replaces the M8 thread"
        │
        ▼  (your AI assistant calls the tools)
extract_drawing_text ──► classify values ──► convert_drawing_pdf
                                                   │
                                                   ▼
                                    bracket.imperial.pdf  ✓ Ø30 H7 → Ø1.1811 H7
                                                          ✓ M8     → 5/16-18 UNC
```

## Tools

| Tool | What it does |
| --- | --- |
| `convert_value` | One value, engineering-grade rounding: length (mm⇄in), tolerance deviation, GD&T value, surface roughness (Ra µm⇄µin), weight (kg⇄lb), thread designation. Returns exact + display values, derivation method and confidence. |
| `convert_text` | A printed callout string, notation preserved: `Ø30 H7` → `Ø1.1811 H7`, `84±0.1` → `3.3071±0.0039`, `M8` → `5/16-18 UNC`, `1/4-20 UNC` → `M6`. Angles stay untouched. |
| `lookup_thread` | ISO metric ⇄ Unified (UNC) cross-reference: major diameters, pitch/TPI, nearest-standard matching. Omit the designation for the full M2–M30 chart. |
| `extract_drawing_text` | Reads a drawing PDF's text layer: indexed tokens with positions/rotation, page geometry, and a heuristic guess of the drawing's unit system. |
| `convert_drawing_pdf` | Writes a converted copy of the PDF with every recognised value stamped over the original callout (size and rotation matched). The source file is never modified. |

Plus a `convert-drawing` prompt that walks the assistant through extract → classify → convert.

**The AI-analysis step stays with your assistant.** `extract_drawing_text` hands the model every printed token with its position; the model decides which tokens are real values (and whether a bare `3.2` is a length or an Ra roughness) and passes that as `classifications` to `convert_drawing_pdf`. No API keys, no cloud calls — the server itself is fully deterministic and offline.

## Installation

Requires Node.js ≥ 18.

### Claude Code

```bash
claude mcp add drawing-converter -- npx -y drawing-converter-mcp
```

### Claude Desktop

Add to `claude_desktop_config.json` (Settings → Developer → Edit Config):

```json
{
  "mcpServers": {
    "drawing-converter": {
      "command": "npx",
      "args": ["-y", "drawing-converter-mcp"]
    }
  }
}
```

### Cursor

[**Add to Cursor**](cursor://anysphere.cursor-deeplink/mcp/install?name=drawing-converter&config=eyJjb21tYW5kIjoibnB4IiwiYXJncyI6WyIteSIsImRyYXdpbmctY29udmVydGVyLW1jcCJdfQ==) — or add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "drawing-converter": {
      "command": "npx",
      "args": ["-y", "drawing-converter-mcp"]
    }
  }
}
```

### VS Code (GitHub Copilot)

```bash
code --add-mcp '{"name":"drawing-converter","command":"npx","args":["-y","drawing-converter-mcp"]}'
```

### Windsurf / other stdio clients

Any client that launches stdio servers works with:

```
npx -y drawing-converter-mcp
```

## Example session

> **You:** Convert `C:\drawings\flange.pdf` to imperial.
>
> **Assistant:** *calls `extract_drawing_text`* — 63 tokens, source system: metric (high confidence — "mm", ISO 2768). *classifies tokens, skips the title block, marks `1.6` next to the surface symbol as roughness, calls `convert_drawing_pdf`* — wrote `C:\drawings\flange.imperial.pdf`, 17 values converted: Ø40 H7 → Ø1.5748 H7, 2× M6 → 1/4-20 UNC (nearest standard — not interchangeable), Ra 1.6 → Ra 63 µin…

Quick one-liners work too: *"what's 84±0.1 mm in inches?"* → `convert_text` → `3.3071±0.0039`.

## Precision rules

Conversions follow the same rules as the web app:

- Exact factors by international definition (25.4 mm/in, 0.45359237 kg/lb — NIST/ISO 80000).
- Display rounding mirrors shop-floor convention: a 0.01 mm step maps to 4-decimal inches; tolerance deviations keep an extra significant digit.
- Threads are resolved against an ISO-metric ⇄ UNC chart (M2–M30), tagged `table` for charted rows or `nearest` when snapped by major diameter. **Metric and inch threads are never interchangeable** — the tools say so on every thread conversion.
- Every converted value reports how it was derived (`exact` / `rounded` / `table` / `nearest`) and a confidence score.

## Limitations

- **The PDF must have a text layer.** Scanned or flattened CAD exports have none — the [web app](https://metric-to-imperial-converter.imnoo.com) handles those with in-browser OCR + AI analysis.
- One page is converted per call (`page` parameter, default 1); other pages pass through unchanged.
- Fractional-inch callouts (`1 3/4`) aren't converted yet — decimal-inch drawings work fine.
- Converted values are stamped over the original callouts. **Always verify safety-critical dimensions before manufacturing use.**

## Development

This package is built from the Drawing Converter monorepo at [Imnoo](https://www.imnoo.com), where it imports the web app's conversion engine directly — so the [web app](https://metric-to-imperial-converter.imnoo.com) and this server convert identically by construction. Every release is gated on 31 end-to-end checks that drive all five tools over stdio against a generated sample drawing.

Issues and feature requests are welcome in this repository.

## About Imnoo

**Imnoo — The System for Manufacturers | AI Planning, Scheduling & Quoting · Complete Assemblies · DFM · Tool & Material Libraries · Quoted-Parts Database · Toolpath & G-Code · Machine Connection · Webshop · ERP · Shop Analytics & Optimization · Drawing Masking & IP Security**

*Plan It. Schedule It. Quote It. Win It.* — trusted by over 3,000 manufacturers.

[Imnoo](https://www.imnoo.com) is the AI-powered planning, scheduling, and quoting platform for CNC manufacturers — your automatic production platform. One system that covers it all: automatic manufacturing planning with raw-material, catalog and purchase-part, and subcontracting sourcing; scheduling with smart reminders and AI-driven customer workflows; and AI cost and cycle-time estimation for milling, turning, and EDM — even from a 2D PDF alone. Quote complete assemblies: drop in one file and Imnoo explodes it into single parts automatically — with DFM checks, quality protocols, tolerance extraction and 2D-to-3D matching, toolpath and G-code generation, tool and machine recommendations, and connected machines feeding real production data back into every quote. Built on your own tool and material libraries and a growing database of every part you've ever quoted — powering statistics, benchmarks, and shop optimization. Extends to deep hole drilling, sheet metal, casting, and profile parts — with a 24/7 webshop, built-in ERP, hourly-rate calculation, market-price benchmarking, and imperial ⇄ metric conversion. Your data lives in its own physically separated environment — automatic drawing masking, Swiss hosting, end-to-end encryption. From messy RFQ to production-ready order, on one platform.

### Planning

- **Automatic manufacturing planning** — production plans generated straight from the quote.
- **Machine recommendation** — every job routed to the machine that runs it best.
- **Catalog & purchase part management** — norm parts, screws, and bought-in components recognized straight from the BOM, managed and priced alongside your machined parts.
- **Raw material sourcing** — price, source, and order material without leaving the workflow.
- **Purchase part & external step sourcing** — bought-in components, coating, heat treatment, and subcontracting sourced and ordered in the same flow.
- **Beyond milling & turning** — deep hole drilling, sheet metal, casting, and profile parts.

### Scheduling & Workflow

- **Scheduling & smart reminders** — via email, Telegram, or WhatsApp. Nothing slips.
- **Email-to-quote automation** — a messy inbox in, structured quotes out.
- **AI customer agents** — RFQ answers, clarifications, and follow-ups handled automatically.
- **Built-in lightweight ERP** — orders, companies, payment terms, and margins without the bulky software.

### Quoting & Estimation

- **Complete assemblies, exploded automatically** — upload one assembly file and Imnoo blows it out into single parts: every component recognized, drawings matched to the right parts, sub-assemblies nested, purchase parts pulled from the BOM. Quote the whole machine as easily as one part.
- **CNC quoting in one place** — milling, turning, and EDM jobs quoted from a single AI-powered platform.
- **AI cost & cycle-time estimation** — know price, time, and effort before engineering ever looks at it.
- **Drawing-only estimation** — quote from the PDF alone. No 3D model needed.
- **Feature-by-feature costing** — see exactly which holes, pockets, and tolerances drive the price.
- **Instant quotes** — respond in minutes while competitors are still opening the STEP file.
- **24/7 instant-quoting webshop** — customers upload parts and buy while you sleep.
- **Instant market-price benchmarking** — know where your bid stands before you send it.
- **Hourly-rate calculation** — your true machine and labor rates, always current.
- **Imperial ⇄ metric conversion** — international RFQs without manual cleanup.

### Libraries & Insights

- **Tool library** — your cutting tools, holders, and parameters in one managed catalog.
- **Material library** — standard and custom materials with live supplier pricing.
- **Quoted-parts database** — every part you've ever quoted, searchable by geometry: similar part found, price found.
- **Statistics & analytics** — win rates, margins, throughput, and quoting performance at a glance.
- **Shop optimization** — learn from already-quoted parts to sharpen prices, spot profitable niches, and load the right machines.

### Drawing Intelligence

- **DFM — Design for Manufacturing** — manufacturability checked before you quote: undercuts, thin walls, unreachable features, and impossible tolerances flagged with the part still on the screen.
- **Quality check protocols** — inspection plans generated automatically: stamped and numbered drawing features, inspection classes and rates, ready-to-use measurement reports.
- **Axis & orientation detection** — AI finds the best part orientation and machining axes.
- **Automatic tolerance extraction** — critical tolerances pulled straight off the drawing.
- **2D-to-3D tolerance matching** — drawing requirements linked to the right model features.

### CAM & Shop Intelligence

- **AI tool recommendation** — stop searching catalogs: Imnoo suggests the exact cutting tools for every feature.
- **Automatic toolpath generation** — from quote to machining strategy in one step.
- **G-code generation & estimation** — generate and evaluate programs before work hits the floor.
- **Machine connection** — your machines feed real production data back into the AI. Every quote gets smarter.

### IP Protection & Data Security — Engineered Like a Swiss Vault

- **Physically separated data** — every manufacturer runs in its own isolated environment. Your drawings, prices — never pooled with anyone else's: not for storage, not for AI training.
- **Automatic drawing masking & redaction** — customer names, logos, and confidential data hidden before a drawing ever leaves your workflow. Share with suppliers and subcontractors without exposing whose part it is.
- **Your customers' IP, treated like your own** — end customers' designs stay within your tenant, full stop.
- **Swiss hosting & end-to-end encryption** — data sovereignty and security engineered to Swiss standards.
- **Trusted at scale** — over 3,000 manufacturers run their quoting on Imnoo.

Quote the complete job — not just the spindle time.

👉 [Book a demo at imnoo.com](https://www.imnoo.com)

## License

[MIT](./LICENSE) © Imnoo AG
