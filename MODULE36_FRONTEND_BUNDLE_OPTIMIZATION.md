# MODULE 36: Frontend Bundle Optimization

Goals: reduce bundle size, improve load times, improve perceived performance via code-splitting, tree-shaking, and analyzer tooling.

Fundamentals:
- Tree shaking, dynamic imports, code-splitting
- Bundle analysis using @next/bundle-analyzer
- Lazy loading of non-critical components
- Inline critical CSS, CSS-in-JS with micro-optimizations
- Use React.lazy and React.Suspense judiciously
- Analyze dependencies; remove dead code

Tech Stack Relevance: Next.js, Vercel, React, SWR/React Query

Implementation Checklist:
- [ ] Enable bundle analyzer in Next.js
- [ ] Identify large modules via analyzer; split into chunks
- [ ] Replace large imports with dynamic imports
- [ ] Audit 3rd-party libraries for tree-shaking friendliness
- [ ] Add lazy-loaded components for non-critical UI
- [ ] Measure baseline bundle size and improvements
- [ ] Document results in STACK_STANDARDS.md

References:
- Next.js Optimizing Bundles: https://nextjs.org/docs/advanced-features/bundle-analysis
- Article: Reduce bundle size with tree shaking (various sources)
