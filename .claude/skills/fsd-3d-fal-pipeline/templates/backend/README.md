# Backend Templates — TODO

Diese Templates sind **noch nicht ausgefuellt**. Geplante Files (aus dem Skill-Bundle):

```
src/server.ts
src/services/{fal-client,cache,storage,optimize}.ts
src/routes/fal/{generate-3d,generate-image,generate-texture,generate-environment,generate-video}.ts
src/middleware/rate-limit.ts
scripts/generate-hero.ts
package.json
```

## Pflicht-Stack (per SKILL.md)

- Hono v4 auf Node 22 LTS
- `@fal-ai/client@^1.6.0` (FAL_KEY nur serverseitig)
- Zod-Validation pro Route
- Cache: In-Memory LRU + Upstash Redis
- Storage: Cloudflare R2 (S3-kompatibel)
- Optimizer: `@gltf-transform/core` v4 + Draco + KTX2/WebP, Sharp v0.34, ffmpeg (libsvtav1)

## Pflicht-Pipeline pro fal-Route

`Zod Validation → Cache Lookup → fal Call → Optimization → R2 Upload → Cache Write`

Kein Step weglassen. Rate-Limit-Middleware ist Pflicht — ohne sie kann ein Bot $1000+/h verbrennen.

Siehe `../../references/04-pitfalls.md` fuer die vollstaendige Checkliste.
