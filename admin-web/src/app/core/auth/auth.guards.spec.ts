import { TestBed } from '@angular/core/testing';
import { UrlTree, provideRouter } from '@angular/router';
import { authGuard, roleGuard } from './auth.guards';
import { AuthService } from './auth.service';

class FakeAuth {
  private authed = false;
  private _role: string | null = null;
  setSession(authed: boolean, role: string | null) {
    this.authed = authed;
    this._role = role;
  }
  waitUntilReady() {
    return Promise.resolve();
  }
  isAuthenticated() {
    return this.authed;
  }
  role() {
    return this._role;
  }
}

describe('auth guards', () => {
  let auth: FakeAuth;

  beforeEach(() => {
    auth = new FakeAuth();
    TestBed.configureTestingModule({
      providers: [{ provide: AuthService, useValue: auth }, provideRouter([])],
    });
  });

  it('authGuard redirects to /login when not authenticated', async () => {
    auth.setSession(false, null);
    const result = await TestBed.runInInjectionContext(() =>
      authGuard({} as never, { url: '/reservas' } as never),
    );
    expect(result).toBeInstanceOf(UrlTree);
  });

  it('authGuard allows when authenticated', async () => {
    auth.setSession(true, 'operator');
    const result = await TestBed.runInInjectionContext(() =>
      authGuard({} as never, { url: '/reservas' } as never),
    );
    expect(result).toBe(true);
  });

  it('roleGuard(admin) blocks operator', async () => {
    auth.setSession(true, 'operator');
    const result = await TestBed.runInInjectionContext(() =>
      roleGuard('admin')({} as never, {} as never),
    );
    expect(result).toBeInstanceOf(UrlTree);
  });

  it('roleGuard(admin) allows admin', async () => {
    auth.setSession(true, 'admin');
    const result = await TestBed.runInInjectionContext(() =>
      roleGuard('admin')({} as never, {} as never),
    );
    expect(result).toBe(true);
  });

  it('roleGuard(operator) allows admin (full access)', async () => {
    auth.setSession(true, 'admin');
    const result = await TestBed.runInInjectionContext(() =>
      roleGuard('operator')({} as never, {} as never),
    );
    expect(result).toBe(true);
  });
});
