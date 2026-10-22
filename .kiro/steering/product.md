# Product

A micro-blogging web application (Twitter-style) where users can register, post short messages, follow other users, and like posts.

## Core Features

- **Authentication**: Email/password sign-up and login backed by Amazon Cognito.
- **Posts**: Create short text posts (max 280 characters), browse a feed sorted by newest or most popular, and like posts.
- **Profiles**: View and edit user profiles, including display name.
- **Social graph**: Follow and unfollow other users; check following status.

## Design Language

The UI follows a modern, social-media-inspired aesthetic: a purple (`#8b5cf6`) and white theme with rounded elements, system fonts, and a mobile-first responsive layout. Full details live in `DESIGN_LANGUAGE.md` at the repo root — consult it before making UI/styling changes to stay consistent.

## Context

This is a lab/learning environment. Resources use `RemovalPolicy.DESTROY` and permissive CORS, which are acceptable for development but not for production.
