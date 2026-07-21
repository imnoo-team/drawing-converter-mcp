# Runs the published drawing-converter-mcp server over stdio.
# Used by Glama to verify the server starts and answers introspection.
FROM node:20-alpine

# The package is pure JS (pdfjs-dist legacy build + pdf-lib), so no build tools needed.
RUN npm install -g drawing-converter-mcp@0.1.0

# stdio transport: the client speaks JSON-RPC over stdin/stdout.
ENTRYPOINT ["drawing-converter-mcp"]
