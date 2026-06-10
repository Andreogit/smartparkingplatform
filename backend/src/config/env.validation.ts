import Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().port().default(3000),
  API_GLOBAL_PREFIX: Joi.string().default('api'),

  DATABASE_URL: Joi.string().required(),

  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRES_IN: Joi.string().default('7d'),

  PASSWORD_BCRYPT_ROUNDS: Joi.number().integer().min(10).max(14).default(12),

  SWAGGER_ENABLED: Joi.boolean().truthy('true').falsy('false').default(true),
  SWAGGER_PATH: Joi.string().default('docs'),

  CORS_ORIGINS: Joi.string().allow('', null),

  GOOGLE_DIRECTIONS_API_KEY: Joi.string().allow('', null),
});
