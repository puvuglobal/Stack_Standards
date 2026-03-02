# MODULE 37: Rate Limiting & WAF Protection

Objective: Harden API surface against abuse; implement rate limiting, WAF rules, and DDoS protection.

Fundamentals:
- Identity-aware rate limiting on critical endpoints (auth, API)
- WAF rules for OWASP top 10 protection
- DDoS mitigation via edge firewall
- Edge middleware-based rate limiting vs gateway-based

Implementation Plan:
- [ ] Configure Vercel WAF with rate limiting rules
- [ ] Implement @vercel/firewall or edge middleware for API throttling
- [ ] Add cooldown windows and IP-based limits
- [ ] Add bot protection and challenge mode when needed
- [ ] Instrument metrics (counts, blocked requests)
- [ ] Add test harness to simulate abuse scenarios

References:
- Vercel WAF Rate Limiting: https://vercel.com/docs/vercel-firewall/vercel-waf/rate-limiting
- DDoS Mitigation: https://vercel.com/docs/vercel-firewall/ddos-mitigation
- Rate Limiting SDK: https://vercel.com/docs/vercel-firewall/rate-limiting-sdk
