import { TestBed } from '@angular/core/testing';
import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { authInterceptor } from './auth.interceptor';
import { AuthService } from '../auth/auth.service';
import { runtimeConfig } from '../config/runtime-config';

class FakeAuth {
  getToken() {
    return Promise.resolve('test-token');
  }
}

describe('authInterceptor', () => {
  let http: HttpClient;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useClass: FakeAuth },
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
      ],
    });
    http = TestBed.inject(HttpClient);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('adds the Bearer token to backend requests', async () => {
    const url = `${runtimeConfig.apiBaseUrl}/api/today`;
    http.get(url).subscribe();
    await new Promise((r) => setTimeout(r, 0));
    const req = httpMock.expectOne(url);
    expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
    req.flush({});
  });

  it('does not add the token to third-party requests', async () => {
    const url = 'https://example.com/data';
    http.get(url).subscribe();
    await new Promise((r) => setTimeout(r, 0));
    const req = httpMock.expectOne(url);
    expect(req.request.headers.has('Authorization')).toBe(false);
    req.flush({});
  });
});
