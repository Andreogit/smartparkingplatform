import { randomUUID } from 'crypto';
import { NextFunction, Request, Response } from 'express';

export function RequestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const headerId = req.headers['x-request-id'];
  const id = typeof headerId === 'string' && headerId.length > 0 ? headerId : randomUUID();
  req.headers['x-request-id'] = id;
  res.setHeader('x-request-id', id);
  next();
}
