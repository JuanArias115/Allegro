import { Injectable, computed, signal } from '@angular/core';
import { initializeApp, type FirebaseApp } from 'firebase/app';
import {
  GoogleAuthProvider,
  getAuth,
  getIdToken,
  getIdTokenResult,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  type Auth,
  type User,
} from 'firebase/auth';
import { environment } from '../../../environments/environment';
import type { Role } from '../models/models';

export interface SessionUser {
  uid: string;
  name: string | null;
  email: string | null;
  role: Role | null;
  appAccess: boolean;
}

/**
 * Autenticación con Firebase Web SDK. Mantiene la sesión y los claims (role,
 * app_access) como signals. El backend SIEMPRE revalida el token y el rol; ocultar
 * botones en el cliente no sustituye esa comprobación.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly app: FirebaseApp = initializeApp(environment.firebase);
  private readonly auth: Auth = getAuth(this.app);

  private readonly _user = signal<SessionUser | null>(null);
  private readonly _ready = signal(false);

  private resolveReady!: () => void;
  private readonly readyPromise = new Promise<void>((r) => (this.resolveReady = r));

  /** Usuario de sesión (con claims) o null. */
  readonly user = this._user.asReadonly();
  /** true cuando ya se resolvió el estado inicial de auth. */
  readonly ready = this._ready.asReadonly();
  readonly isAuthenticated = computed(() => this._user() !== null);
  readonly role = computed<Role | null>(() => this._user()?.role ?? null);
  readonly isAdmin = computed(() => this.role() === 'admin');

  constructor() {
    onAuthStateChanged(this.auth, async (fbUser) => {
      this._user.set(fbUser ? await this.toSessionUser(fbUser) : null);
      this._ready.set(true);
      this.resolveReady();
    });
  }

  /** Resuelve cuando ya se conoce el estado inicial de autenticación. */
  waitUntilReady(): Promise<void> {
    return this.readyPromise;
  }

  async loginWithEmail(email: string, password: string): Promise<void> {
    await signInWithEmailAndPassword(this.auth, email, password);
  }

  async loginWithGoogle(): Promise<void> {
    await signInWithPopup(this.auth, new GoogleAuthProvider());
  }

  async logout(): Promise<void> {
    await signOut(this.auth);
  }

  /** ID token vigente (refresca automáticamente si está por expirar). */
  async getToken(forceRefresh = false): Promise<string | null> {
    const current = this.auth.currentUser;
    return current ? getIdToken(current, forceRefresh) : null;
  }

  private async toSessionUser(fbUser: User): Promise<SessionUser> {
    const token = await getIdTokenResult(fbUser);
    const claims = token.claims;
    const role = (claims['role'] as Role | undefined) ?? null;
    const appAccess = claims['app_access'] === true || claims['app_access'] === 'true';
    return {
      uid: fbUser.uid,
      name: fbUser.displayName,
      email: fbUser.email,
      role,
      appAccess,
    };
  }
}
