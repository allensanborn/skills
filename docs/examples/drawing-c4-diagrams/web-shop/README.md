# Sample: web shop (grilled from a one-line prompt)

What a typical first run looks like: a bare request, the **scoping grill** one question at a time, then validated and rendered System Context and Container views, then the first **review grill** question.

Generated 2026-11-17 by running the real skill headless, unedited: `claude -p` with the `allensanborn-skills` plugin loaded from commit `1c96516` (`--plugin-dir`), model `claude-opus-5-5`, Tier 1 (Docker, headless Structurizr `2026.10.26-playwright`, no MCP), user settings excluded (`--setting-sources project,local`) so no personal instructions leaked in. The skill's replies below are verbatim; only the headings between turns are added. Total cost: $2.67 across 8 turns. The user answers were scripted to read like a real developer's: mostly accepting the recommendation, sometimes adding a detail (Amazon SES, Stripe) that the grill then folded in.

## Output

| File | What it is |
| --- | --- |
| [workspace.dsl](./workspace.dsl) | The one model both views come from |
| [SystemContext.svg](./SystemContext.svg) | System Context view |
| [Containers.svg](./Containers.svg) | Container view |

![System Context](./SystemContext.svg)

![Containers](./Containers.svg)

## Transcript

<!-- Verbatim chat output: chat-style lists and bold leads are kept as written. -->
<!-- markdownlint-disable MD032 MD034 MD036 -->

### Turn 1

**User:**

> I have a web app: a React SPA, a Spring Boot API, and a Postgres database. Customers use it; it also emails them via our SMTP server. Draw the C4 diagrams.

**Skill:**

Your config is already set up: Tier 1 (Docker, headless), with diagrams going in `docs/architecture/`.

Before I write any DSL, I'll ask six short scoping questions, one at a time: **audience, system boundary, one system or many, people, external systems, and C4 level.** Each one comes with a recommended answer, so you can reply "yes" to take it. You've already answered some of this (customers, an SMTP server), so a few will just be confirmations.

**Q1: Audience and purpose.** Who will read these diagrams, and what should they help with? Onboarding a new engineer, a design review, or explaining scope to non-technical stakeholders?

*Recommended:* **developers on your team, to give everyone the same picture of how the system fits together.** That means technology labels (React, Spring Boot, PostgreSQL, SMTP) belong on the diagrams.

### Turn 2

**User:**

> Yes, developers. Mostly for onboarding new engineers.

**Skill:**

**Q2: The system boundary.** Everything you build and own goes inside one software-system box. Everything else is a person or an external system.

*Recommended:* **one system, called "Web Shop", containing the React SPA, the Spring Boot API, and the Postgres database.** The SMTP server stays outside it as an external system, because you send mail through it but don't build it.

Does that match? One thing to check: is the SMTP server something your team runs and configures (e.g. your own Postfix), or a provider like SendGrid/SES? It stays external either way. The answer just changes how we label it.

### Turn 3

**User:**

> Yes, call it Web Shop. The SMTP server is Amazon SES.

**Skill:**

Noted: **Web Shop** is the system, and **Amazon SES** is an external system it sends email through.

**Q3: One system or many.** Is Web Shop the only system in this workspace, or does it sit alongside other systems owned by other teams or repos (an admin back-office, a separate payments service, a warehouse system)?

*Recommended:* **one system, one workspace.** That's Structurizr's default and fits a single SPA + API + DB app. If other in-house systems talk to Web Shop, we show them as external boxes on the Context diagram rather than modeling their insides.

### Turn 4

**User:**

> One system. We also take card payments through Stripe, if that matters.

**Skill:**

Stripe matters. It's exactly the kind of external system that gets left off these diagrams. I'll add **Stripe** as an external system next to Amazon SES. One follow-up for later: does the SPA talk to Stripe directly (Stripe.js / Elements for card entry), or does only the API call it? That decides where the arrows go on the Container diagram.

**Q4: People.** Who uses Web Shop? You've said "customers". Is anyone else hands-on, such as staff who manage products and orders, or support agents handling refunds?

*Recommended:* **one Person, "Customer"** (browses, orders, pays, receives emails), **plus a separate "Shop Staff / Admin" Person** if anyone manages the catalog or orders through Web Shop itself. Each distinct role gets its own box rather than one generic "users" box.

### Turn 5

**User:**

> Just customers for now. On Stripe: the SPA uses Stripe Elements for card entry, and the API confirms the payment.

**Skill:**

Got it. **Customer** is the only Person. On the Container diagram, both the SPA (Stripe Elements card entry) and the API (payment confirmation) will have arrows to Stripe.

**Q5: External systems.** So far there are two: **Amazon SES** (email) and **Stripe** (payments). Is there anything else? Common ones:
- **Sign-in:** your own login in the API, or an identity provider (Cognito, Auth0, Google sign-in)?
- **Inbound webhooks:** does Stripe call back into your API (e.g. `payment_intent.succeeded`)?
- **Anything else:** analytics, shipping/tax APIs, object storage for product images?

*Recommended:* **SES + Stripe, with Stripe webhooks back into the API if you use them.** Leave out anything that's only monitoring or infrastructure. That belongs on a Deployment diagram.

### Turn 6

**User:**

> Login is our own, in the API. Yes, Stripe sends webhooks to the API. Nothing else.

**Skill:**

The external systems are settled: **Amazon SES** and **Stripe**, with Stripe webhooks coming into the API. Login is built into the API, so there's no external identity provider.

**Q6: Which C4 levels.** This is the last question.

*Recommended:* **System Context + Container now.** Context shows Customer → Web Shop → SES/Stripe, which is what a new engineer needs on day one. Container zooms into the SPA, the API, and Postgres, with the Stripe Elements and webhook arrows. Skip Component for now. If onboarding later needs the inside of the Spring Boot API (controllers, payment service, mailer), we can add that view to the same model.

Go with Context + Container?

### Turn 7

**User:**

> Yes, Context and Container.

**Skill:**

I've drawn the System Context and Container diagrams for Web Shop. The model passes Structurizr's validation, and I opened both rendered images to check them.

**Files** (in `docs/architecture/`):
- `workspace.dsl`: the source for both diagrams.
- `exports/SystemContext.png` / `.svg`: Web Shop with Customer, Stripe and Amazon SES around it.
- `exports/Containers.png` / `.svg`: the React app, the Spring Boot API and Postgres inside Web Shop.
- `exports/*-key.png` / `.svg`: a legend for each diagram.

**What the diagrams show**
- **Customer** uses the React app in their browser.
- **React app → API:** JSON over HTTPS.
- **API → Postgres:** SQL over JDBC.
- **Stripe:** card details go from the React app straight to Stripe through Stripe Elements. The API confirms the payment with Stripe, and Stripe sends webhooks back to the API.
- **Amazon SES:** the API sends email through SES over SMTP, and SES delivers it to the Customer.

**Two fixes during the check**
- On the first Container render, the API → SES arrow ran straight through the Stripe box. I switched that diagram to a top-to-bottom layout, which fixed it.
- I set the workspace scope and added a technology to the two edges that go to and from the Customer.

**Still flagged:** Structurizr's model check still reports two items: no written documentation and no architecture decision records for Web Shop. Neither affects the diagrams.

---

Now some review questions about what the diagrams show. You can skip them by saying "skip the grill". One at a time, starting with the gap I'm least sure about:

**R1: How does the React app get to the customer's browser?** At the moment the Customer just "uses" the React app, and nothing serves it. A new engineer will ask where the HTML and JS bundle come from. The answer decides whether there's a fourth container:

- **(a)** Spring Boot serves the built bundle as static resources. No new box; I'd add "Serves the SPA" to the API's description.
- **(b)** It's hosted separately, e.g. S3 + CloudFront or Nginx. That's a static-content container (or a note for a later Deployment diagram), with an arrow "Delivers the SPA to" the Customer's browser.

*Recommended:* **(a), if that's how it works today.** It keeps the diagram at three containers and is the common Spring Boot setup. Which is it?

### Turn 8

**User:**

> (a), Spring Boot serves the bundle. That's enough review for now, thanks.

**Skill:**

I updated the diagrams with your answer. The API Application box on the Container diagram now says it **serves the SPA bundle**, so there's still no fourth container. The model passed validation again and I re-rendered both diagrams. I looked at the new Container image: no arrows cross boxes and every label is readable.

**Files** (all in `docs/architecture/`):
- `workspace.dsl`: the source for both diagrams. Edit this, not the images.
- `exports/SystemContext.png` / `.svg`: Customer, Web Shop, Stripe and Amazon SES.
- `exports/Containers.png` / `.svg`: the React app, the Spring Boot API and Postgres, with the Stripe and SES connections.
- `exports/*-key.png` / `.svg`: a legend for each diagram.

For the repo, use the PNG or SVG files. Each image prints the time it was rendered, so every re-render changes the files even if the diagram didn't. Run `git checkout` on any you didn't mean to change before committing.

We stopped the review there, so these questions are still open:
- **Sync or async:** Does the API send email inside the request, or through a background job or queue? If it's a queue, that's another box on the Container diagram.
- **Webhook security:** Does the API check the signatures on Stripe's webhooks? This is worth writing down for new engineers, either on the diagram or in the docs.
- **Docs and decisions:** Structurizr's model check still flags that Web Shop has no written docs and no architecture decision records. It doesn't affect the diagrams. Add them if you want the onboarding material in one place.

To pick up later, re-run the export, or start `structurizr/structurizr local` and adjust the layout by hand at `http://localhost:8080`.
