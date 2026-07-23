# Mystic BBS HTTP File Server

## Overview

MIS includes a built-in HTTP/1.0 file server on port 8080.
It serves static web pages and BBS file downloads.

## Setup

1. Create the `webroot/` directory under your Mystic root:
   - Windows: `C:\mystic\webroot\`
   - Linux: `/mystic/webroot/`

2. Place your web files here:
   - `index.htm` — your BBS home page (required)
   - Any HTML, CSS, images, or static files

3. Start MIS — the HTTP server starts automatically on port 8080.

4. Browse to `http://your-bbs:8080/`

## URL Mapping

| URL | Serves from |
|-----|-------------|
| `/` | `webroot/index.htm` |
| `/page.html` | `webroot/page.html` |
| `/images/logo.png` | `webroot/images/logo.png` |
| `/Games/doom.zip` | File base download (via FTP Name) |

## File Downloads

Files from your BBS file bases are accessible via HTTP using the
same FTP Name mapping as the FTP server:

1. In the File Base Editor, set:
   - **FTP Name** = directory name (e.g. `Games`)
   - **FTP ACS** = access level (e.g. `s20`)

2. Files are then available at:
   `http://your-bbs:8080/Games/filename.zip`

3. The file is served directly from the file base path.
   No copying or temp files needed.

## Content Types

The server detects content type by file extension:

| Extension | Content-Type |
|-----------|-------------|
| .htm .html | text/html |
| .txt .nfo .diz | text/plain |
| .zip .rar .arj .lha | application/octet-stream |
| .gif | image/gif |
| .jpg .jpeg | image/jpeg |
| .png | image/png |
| .mp3 | audio/mpeg |
| .mp4 .m4a | video/mp4 |
| (other) | application/octet-stream |

## Security

- Path traversal blocked (`..` and `\` rejected)
- Only serves files from `webroot/` and configured file bases
- FTP ACS controls file base access
- No directory listing (returns 404 for directories)

## Technical Details

- HTTP/1.0 (one request per connection)
- Port 8080 (hardcoded, configurable in future)
- Max 10 simultaneous connections
- Logs to `http.log`
- 32KB transfer buffer
- Content-Disposition header forces download for non-HTML files

## Terminal Integration

SyncTERM and NetRunner can detect FTP/HTTP URLs in the terminal
data stream and auto-launch downloads. When the BBS shows a
download URL via prompt 531, these terminals handle it automatically.

## Limitations

- No HTTPS/TLS (plain HTTP only)
- No authentication on web pages (file base ACS applies to downloads)
- No CGI or server-side scripting
- No directory listing
- Port 8080 hardcoded until config is added to mystic.dat
- No MCI code processing in HTML files (static only)
