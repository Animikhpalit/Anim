# Project Structure

```
environment/
├── backend/            # AWS Lambda functions (Node.js, plain JS)
│   ├── scripts/        # Lambda packaging + deploy scripts (.sh and .ps1)
│   └── src/
│       ├── common/     # Shared code (middleware.js — withAuth)
│       └── functions/  # Lambda handlers grouped by domain
│           ├── auth/        # login.js, register.js
│           ├── users/       # getProfile, updateProfile, followUser, unfollowUser, checkFollowing
│           ├── posts/       # createPost, getPosts, likePost
│           └── monitoring/  # emitCustomMetrics
├── frontend/           # React + TypeScript (Vite) SPA
│   └── src/
│       ├── components/ # Reusable UI components
│       ├── contexts/   # React contexts (AuthContext)
│       ├── pages/      # Route-level views (Feed, Login, Register, Profile, CreatePost)
│       ├── services/   # api.ts — all backend HTTP calls
│       └── types/      # Shared TS types (user.ts, post.ts)
├── infrastructure/     # AWS CDK v2 (TypeScript)
│   ├── bin/app.ts      # CDK app entry point
│   └── lib/app-stack.ts# Single AppStack with all resources
├── deploy-backend.ps1  # Root-level full backend deploy
├── deploy-frontend.ps1 # Root-level full frontend deploy
└── DESIGN_LANGUAGE.md  # UI/styling reference
```

## Conventions

### Backend Lambda functions
- Each handler lives under `src/functions/<domain>/<name>.js` and exports `exports.handler`.
- Handler file name maps to the CDK function's `handler` (e.g. `createPost.handler`) and to its package zip name (`createPost.zip`). When adding a function, register it in `infrastructure/lib/app-stack.ts` with its own Lambda, environment variables, IAM grants, and API route.
- **Authentication**: wrap protected handlers with `withAuth` from `../../common/middleware`. It verifies the Cognito ID token, resolves the internal user via the `username-index` GSI, and injects `event.user = { id, username }`. Auth'd functions need `USER_POOL_ID`, `USER_POOL_CLIENT_ID`, and `USERS_TABLE` env vars (see the `authEnv()` helper in the stack). Fail closed if config is missing.
- **Responses**: return API Gateway shape `{ statusCode, headers, body: JSON.stringify(...) }`. Always include JSON + CORS headers (`Content-Type`, `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Credentials`).
- **Errors**: `try/catch` every handler. Log full error detail server-side with `console.error`; return a generic message to the client (never leak internals or token-verification reasons).
- **Validation**: validate input early and return `400` for bad input (e.g. empty content, content over 280 chars).
- Initialize AWS SDK clients at module scope (outside the handler) so they are reused across warm invocations.
- Use `@aws-sdk/lib-dynamodb` `DynamoDBDocumentClient` for DynamoDB access; read table names from environment variables, never hard-code them.

### DynamoDB access patterns
Tables are keyed and indexed for specific queries — prefer the matching GSI over scans:
- **Users**: PK `id`; GSI `username-index` (by `username`).
- **Posts**: PK `id`; GSI `userId-index` (by `userId`, sort `createdAt`).
- **Likes**: PK `userId` + SK `postId`; GSI `postId-index`.
- **Comments**: PK `id`; GSI `postId-index` (sort `createdAt`).
- **Follows**: PK `followerId` + SK `followeeId`; GSI `followee-index`.

### Frontend
- Keep all backend calls in `src/services/api.ts`, grouped by domain (`authApi`, `usersApi`, `postsApi`). Pass the auth `token` explicitly and send it as `Authorization: Bearer <token>`.
- Route-level views go in `pages/`, shared pieces in `components/`, cross-cutting state in `contexts/`, shared shapes in `types/`.
- Styling follows `DESIGN_LANGUAGE.md` (CSS variables, purple theme, mobile-first).

### Infrastructure
- All resources are defined in the single `AppStack`. Follow the existing pattern when adding resources: create the construct, grant least-privilege IAM (`grantReadData` / `grantReadWriteData`), wire the API route, and add any needed `CfnOutput`.
- Lab-only settings (`RemovalPolicy.DESTROY`, permissive CORS, `allowCredentials`) are intentional here but should not be copied into production specs.
