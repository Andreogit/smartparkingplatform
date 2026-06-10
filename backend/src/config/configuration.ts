export default () => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  http: {
    port: parseInt(process.env.PORT ?? '3000', 10),
    globalPrefix: process.env.API_GLOBAL_PREFIX ?? 'api',
  },
  database: {
    url: process.env.DATABASE_URL,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },
  security: {
    passwordBcryptRounds: parseInt(process.env.PASSWORD_BCRYPT_ROUNDS ?? '12', 10),
  },
  swagger: {
    enabled: process.env.SWAGGER_ENABLED !== 'false',
    path: process.env.SWAGGER_PATH ?? 'docs',
  },
  cors: {
    origins: process.env.CORS_ORIGINS?.split(',').map((o) => o.trim()).filter(Boolean),
  },
  google: {
    directionsApiKey: process.env.GOOGLE_DIRECTIONS_API_KEY?.trim() ?? '',
  },
});
