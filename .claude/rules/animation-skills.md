# Animation-Skills Regel

## Meta-Orchestrator

Verantwortlich: Animation Designer Agent (opusplan)

| Skill                 | Wann nutzen                                   | Pflicht bei                      |
| --------------------- | --------------------------------------------- | -------------------------------- |
| `/animation-designer` | Animations-Strategie planen und orchestrieren | Jeder nicht-trivialen Animation  |
| `/emil-design-eng`    | Emil Kowalski Design-Prinzipien anwenden      | UI-Polish, Easing-Entscheidungen |

## Web Animation Skills

Verantwortlich: Animation Designer, Senior Frontend

| Skill             | Wann nutzen                                 | Pflicht bei                     |
| ----------------- | ------------------------------------------- | ------------------------------- |
| `/animate`        | UI Micro-Interactions und State Transitions | Neuen interaktiven Components   |
| `/css-animation`  | HTML/CSS Walkthrough-Demos erstellen        | Feature-Demos und Onboarding    |
| `/gsap`           | Komplexe GSAP Timelines und ScrollTrigger   | Scroll-Animationen, Pinning     |
| `/three`          | Three.js/WebGL 3D-Szenen                    | 3D-Visualisierungen             |
| `/typegpu`        | TypeGPU/WebGPU Shader und Partikel          | GPU-beschleunigte Effekte       |
| `/lottie`         | Lottie/dotLottie After Effects Exports      | Illustrationsanimationen        |
| `/waapi`          | Web Animations API (native Browser)         | Performante Browser-Animationen |
| `/animejs`        | Anime.js Patterns                           | Anime.js-basierte Projekte      |
| `/css-animations` | CSS Keyframes (HyperFrames Adapter)         | CSS-only Motion in Videos       |
| `/tailwind`       | Tailwind CSS v4 Browser-Runtime             | Tailwind-basierte Animationen   |

## Mobile Animation Skills

Verantwortlich: Animation Designer

| Skill                 | Wann nutzen                            | Pflicht bei             |
| --------------------- | -------------------------------------- | ----------------------- |
| `/flutter-animations` | Flutter Implicit/Explicit/Hero/Physics | Jeder Flutter-Animation |

## Animation Hard Rules

- NIEMALS bounce/elastic Easing — wirkt veraltet
- NIEMALS Layout-Properties animieren (width, height) — nur transform/opacity
- IMMER `prefers-reduced-motion` respektieren
- UI-Feedback unter 300ms, State Transitions 200-500ms
- Exit-Animationen = 75% der Entrance-Duration
- Custom Easing Curves statt CSS-Defaults:
  - `ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1)`
  - `ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1)`
