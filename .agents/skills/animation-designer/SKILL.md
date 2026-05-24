---
name: animation-designer
description: Plan and orchestrate animations across Web (CSS, GSAP, Three.js, WAAPI), Mobile (Flutter), and Video (HyperFrames). Selects optimal animation technology per use case, defines motion language, and ensures performance and accessibility.
user-invokable: true
args:
  - name: mode
    description: 'audit | plan | implement | review'
    required: false
  - name: target
    description: The feature, component, or page to animate
    required: false
---

Orchestrate animation strategy across platforms. Select the right technology, define motion tokens, and ensure consistent, performant, accessible motion design.

## MANDATORY PREPARATION

### Context Gathering (Do This First)

You cannot make good animation decisions without understanding:

- **Platform**: Web (React), Mobile (Flutter), Video (HyperFrames), or multi-platform?
- **Target audience**: Motion-sensitive? Power users? General consumer?
- **Brand personality**: Playful vs professional, energetic vs calm
- **Performance constraints**: Mobile-first? Complex page? Low-end devices?
- **Existing motion language**: Are there established easing curves, durations, patterns?

Attempt to gather these from the current thread, codebase, or design tokens.

1. If you must infer, STOP and call AskUserQuestionTool to verify.
2. If confidence is medium or lower, STOP and ask clarifying questions.

Do NOT proceed without clear context.

### Load Required Skills

Based on the platform and use case, load the appropriate skills:

- **Web UI motion**: Use `animate` skill (Impeccable) + `emil-design-eng` principles
- **CSS-only demos**: Use `css-animation` skill
- **Complex timelines**: Use `gsap` skill
- **3D/WebGPU**: Use `three` or `typegpu` skill
- **Illustration animation**: Use `lottie` skill
- **Native browser**: Use `waapi` skill
- **Flutter mobile**: Use `flutter-animations` skill
- **Video production**: Use `hyperframes`, `hyperframes-cli`, `hyperframes-media` skills

---

## MODE: AUDIT

Analyze an existing feature or codebase for animation opportunities and issues.

1. Scan for existing animations — CSS transitions, JS animations, animation libraries
2. Identify issues:
   - Layout property animations (width, height, top, left) → must use transform
   - Missing `prefers-reduced-motion` support
   - Inconsistent easing curves or durations
   - Bounce/elastic easing (outdated)
   - Animations without purpose
   - Performance bottlenecks (janky animations, layout thrashing)
3. Identify opportunities:
   - Missing feedback on interactive elements
   - Jarring state transitions
   - Unclear spatial relationships
   - Opportunities for delight

Output a structured report with severity ratings.

## MODE: PLAN

Create a comprehensive animation strategy for a feature or project.

1. **Technology Selection Matrix**:

| Animation Type   | Recommended Tech          | Duration   | Easing              |
| ---------------- | ------------------------- | ---------- | ------------------- |
| Button feedback  | CSS transition            | 100-150ms  | ease-out-quart      |
| Modal open/close | Framer Motion / WAAPI     | 200-300ms  | ease-out-expo       |
| Page transition  | View Transitions API      | 300-400ms  | ease-out-quart      |
| Scroll effects   | GSAP ScrollTrigger        | varies     | custom              |
| 3D hero scene    | Three.js                  | continuous | n/a                 |
| App walkthrough  | CSS Animation Skill       | n/a        | custom              |
| Marketing video  | HyperFrames               | n/a        | GSAP timeline       |
| Flutter screen   | Flutter implicit/explicit | 200-400ms  | Curves.easeOutQuart |

2. **Define Motion Tokens** for the project
3. **Prioritize**: Hero moment first, then feedback, then transitions, then delight
4. **Estimate**: Complexity and performance impact per animation

## MODE: IMPLEMENT

Execute the animation plan using the appropriate skills.

1. Set up motion tokens in `shared/config/animation.ts`
2. Delegate to platform-specific skills
3. Verify each animation meets quality criteria
4. Run performance checks

## MODE: REVIEW

Quality-gate review of implemented animations.

1. Performance: 60fps on target devices
2. Accessibility: `prefers-reduced-motion` respected everywhere
3. Consistency: Easing and duration follow motion tokens
4. Purpose: Every animation improves UX
5. Technology: Correct tool chosen for each animation type

---

## HARD RULES

- NEVER use bounce or elastic easing — feels dated
- NEVER animate layout properties — use transform only
- ALWAYS implement `prefers-reduced-motion`
- ALWAYS stay under 16ms per frame budget
- Exit animations = 75% of entrance duration
- UI feedback animations MUST be under 300ms
- One hero animation beats scattered animations everywhere
