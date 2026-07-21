# Drawing Converter MCP Server

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

## License

[MIT](./LICENSE) © Imnoo AG
