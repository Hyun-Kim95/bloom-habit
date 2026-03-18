import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

/** DB 연결 끊김/타임아웃 시 한 번만 재시도 */
function isConnectionError(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  const cause = err instanceof Error && 'cause' in err ? (err as any).cause : null;
  const causeMsg = cause instanceof Error ? cause.message : '';
  return (
    /Connection terminated|connection timeout|ECONNRESET|ECONNREFUSED|Connection refused|Connection closed/i.test(
      msg,
    ) || /Connection terminated|unexpectedly/i.test(causeMsg)
  );
}

@Injectable()
export class DbRetryInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const maxAttempts = 2;
    let attempt = 0;

    const tryNext = (): Observable<unknown> =>
      next.handle().pipe(
        catchError((err) => {
          attempt += 1;
          if (attempt < maxAttempts && isConnectionError(err)) {
            return tryNext();
          }
          return throwError(() => err);
        }),
      );

    return tryNext();
  }
}
