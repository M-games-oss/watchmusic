import express from "express";
import { execFile } from "child_process";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import basicAuth from "express-basic-auth";
import dotenv from "dotenv";

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;
const CACHE_DIR = path.join(__dirname, "cache");

if (!fs.existsSync(CACHE_DIR)) fs.mkdirSync(CACHE_DIR);

// Optional HTTP Basic Auth, same pattern as VinylWave. Leave AUTH_USERNAME
// unset in .env to disable auth entirely (fine for local-network-only use).
if (process.env.AUTH_USERNAME) {
  app.use(
    basicAuth({
      users: { [process.env.AUTH_USERNAME]: process.env.AUTH_PASSWORD || "" },
      challenge: true,
    })
  );
}

// GET /api/search?q=some+song
app.get("/api/search", (req, res) => {
  const query = req.query.q;
  if (!query || typeof query !== "string") {
    return res.status(400).json({ error: "Missing q parameter" });
  }

  const searchTerm = `ytsearch10:${query}`;
  execFile(
    "yt-dlp",
    ["-j", "--flat-playlist", "--no-warnings", searchTerm],
    { maxBuffer: 1024 * 1024 * 10 },
    (err, stdout) => {
      if (err) {
        console.error("Search error:", err.message);
        return res.status(500).json({ error: "Search failed" });
      }
      const lines = stdout.trim().split("\n").filter(Boolean);
      const songs = lines.map((line) => {
        const info = JSON.parse(line);
        return {
          id: info.id,
          title: info.title,
          artist: info.uploader || info.channel || null,
          thumbnail: info.thumbnails?.at(-1)?.url || null,
          duration: Math.round(info.duration || 0),
        };
      });
      res.json(songs);
    }
  );
});

// GET /api/download/:id -> audio bytes, cached on disk after first fetch
app.get("/api/download/:id", (req, res) => {
  const { id } = req.params;

  // Basic sanity check on the video ID shape to avoid shell/arg weirdness
  if (!/^[a-zA-Z0-9_-]{6,20}$/.test(id)) {
    return res.status(400).json({ error: "Invalid video id" });
  }

  const filePath = path.join(CACHE_DIR, `${id}.m4a`);

  if (fs.existsSync(filePath)) {
    return res.sendFile(filePath);
  }

  const url = `https://www.youtube.com/watch?v=${id}`;
  execFile(
    "yt-dlp",
    ["-x", "--audio-format", "m4a", "--no-warnings", "-o", filePath, url],
    { maxBuffer: 1024 * 1024 * 50 },
    (err) => {
      if (err) {
        console.error("Download error:", err.message);
        return res.status(500).json({ error: "Download failed" });
      }
      if (!fs.existsSync(filePath)) {
        return res.status(500).json({ error: "yt-dlp did not produce the expected file" });
      }
      res.sendFile(filePath);
    }
  );
});

app.listen(PORT, () => {
  console.log(`yt-dlp server running on http://localhost:${PORT}`);
});
