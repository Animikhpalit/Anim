# Tech Stack

The project is a three-part monorepo: `frontend`, `backend`, and `infrastructure`. Each has its own `package.json` and is installed/built independently.

## Frontend (`frontend/`)

- **React 18** + **TypeScript**, bundled with **Vite 4**.
- **react-router-dom 6** for routing.
- **Playwright** for end-to-end tests.
- **ESLint** (with `@typescript-eslint`) for linting.
- API calls go through `src/services/api.ts` using the native `fetch` API. The backend base URL comes from `import.meta.env.VITE_API_URL` (configured via `frontend/.env`).

## Backend (`backend/`)

- **Node.js 22** AWS Lambda functions written in **plain JavaScript** (CommonJS `require`/`module.exports`), not TypeScript. A `tsconfig.json` exists but source files are `.js`.
- **AWS SDK v3** clients: `@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb` (DocumentClient), `@aws-sdk/client-cognito-identity-provider`, `@aws-sdk/client-cloudwatch`.
- **aws-jwt-verify** for Cognito ID-token verification.
- **uuid** for generating entity IDs.
- Jest is listed as a dev dependency.

## Infrastructure (`infrastructure/`)

- **AWS CDK v2** (`aws-cdk-lib`, `constructs`) in **TypeScript**, run with `ts-node`.
- Single stack `AppStack` (`lib/app-stack.ts`) provisioning: Cognito User/Identity Pools, DynamoDB tables, API Gateway (REST), Lambda functions, S3 + CloudFront for frontend hosting.

## Common Commands

> Note: this is a Windows environment (cmd/PowerShell). The npm `build`/`deploy` scripts in `backend/package.json` use Unix tooling (`mkdir -p`, `cp`, `find`, `zip`); on Windows use the PowerShell deploy scripts instead, which replicate those steps.

### Frontend
```
cd frontend
npm install
npm run dev         # local dev server (run manually in your terminal)
npm run build       # tsc + vite build -> dist/
npm run lint        # eslint, max-warnings 0
npm run test:e2e    # Playwright e2e tests
```

### Infrastructure
```
cd infrastructure
npm install
npm run build       # tsc
npm run diff        # cdk diff
npm run deploy      # cdk deploy
```

### Full deploy (from repo root, PowerShell)
```
./deploy-backend.ps1    # builds backend, packages Lambdas, deploys AppStack via CDK
./deploy-frontend.ps1   # builds frontend, syncs to S3, invalidates CloudFront
```

## Important Notes

- **Do NOT run `cdk bootstrap`** — bootstrap is pre-configured in the lab environment and running it will fail.
- Default stack name is `AppStack`; override with the `STACK_NAME` environment variable.
- Lambda packaging is per-function: `backend/scripts/prepare-lambda-packages.*` creates one zip per handler under `backend/dist/lambda-packages/`, bundling only the dependencies each function actually uses (e.g. `aws-jwt-verify` is added only for functions that use `withAuth`).
