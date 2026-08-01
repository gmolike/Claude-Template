# Frontend Templates — TODO

Diese Templates sind **noch nicht ausgefuellt**. Geplante Files (aus dem Skill-Bundle):

```
shared/config/fal/endpoints.ts
shared/api/fal/{client,types,index}.ts
shared/lib/react-query/fal-queries.ts
shared/lib/motion/{variants,page-transition,use-reduced-motion-preference,use-scroll-animation}.ts
shared/config/motion/tokens.ts
app/providers/MotionProvider.tsx
widgets/hero-scene/ui/{HeroSceneWidget,HeroCanvas,HeroFlyThrough}.tsx
```

## Befuellen

Wenn die Skill-Templates ausgefuellt werden sollen:

1. Komplette TypeScript-Files aus den Vorantworten / Referenz-Implementierungen einfuegen.
2. JSDoc + `@file`-Header pro File pflegen.
3. Named Exports bevorzugen, `default` nur fuer Route-Komponenten.
4. SemVer pinnen (`hono@^4.6.0`, nicht `latest`).

Siehe `../../SKILL.md` fuer Hard Rules + Setup-Commands.
