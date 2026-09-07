#!/usr/bin/env python3
"""Opt-in live auth smoke test. Creates one dedicated test user; prints no secrets.

Run only against a development API:
  python3 tool/auth_smoke_test.py --base-url http://localhost:8080 --create-test-account
The account remains for inspection. No existing users are changed.
"""
import argparse
import json
import secrets
import urllib.error
import urllib.request


def request(base, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(base + '/api/v1' + path,
        data=json.dumps(body).encode() if body is not None else None,
        headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        # Do not emit error bodies: some services echo submitted credentials.
        return error.code, {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', required=True)
    parser.add_argument('--create-test-account', action='store_true', required=True)
    args = parser.parse_args()
    base = args.base_url.rstrip('/')
    username = 'auth_audit_' + secrets.token_hex(5)
    password = 'AuditAa9!' + secrets.token_urlsafe(24)
    sessions = []

    def check(condition, label):
        if not condition:
            raise RuntimeError('FAIL: ' + label)
        print('PASS: ' + label, flush=True)

    try:
        status, registered = request(base, '/auth/register', {
            'username': username, 'displayName': 'Auth audit test',
            'password': password, 'email': username + '@example.invalid',
        })
        check(status in (200, 201) and bool(registered.get('accessToken'))
              and bool(registered.get('refreshToken')), f'registration issues token pair (HTTP {status})')
        print('Created development test user: ' + username, flush=True)
        sessions.append(registered['refreshToken'])
        status, profile = request(base, '/auth/me', token=registered['accessToken'])
        check(status == 200 and profile.get('username') == username, 'registered session loads profile')
        status, logged_in = request(base, '/auth/login', {'username': username, 'password': password})
        check(status == 200 and bool(logged_in.get('refreshToken')), 'password login')
        sessions.append(logged_in['refreshToken'])
        status, refreshed = request(base, '/auth/refresh', {'refreshToken': logged_in['refreshToken']})
        check(status == 200 and bool(refreshed.get('accessToken')) and bool(refreshed.get('refreshToken')),
              'refresh issues token pair')
        sessions.append(refreshed['refreshToken'])
        status, profile = request(base, '/auth/me', token=refreshed['accessToken'])
        check(status == 200 and profile.get('username') == username, 'refreshed session loads same profile')
        status, _ = request(base, '/auth/logout', {'refreshToken': refreshed['refreshToken']})
        check(status in (200, 204), 'logout')
        status, _ = request(base, '/auth/refresh', {'refreshToken': refreshed['refreshToken']})
        check(status in (400, 401, 403), 'logged-out refresh token rejected')
        status, _ = request(base, '/auth/me')
        check(status in (400, 401, 403), f'anonymous profile request rejected (HTTP {status})')
    finally:
        for token in set(sessions):
            request(base, '/auth/logout', {'refreshToken': token})
        if sessions:
            print('Test user retained for inspection; issued refresh tokens revoked.', flush=True)


if __name__ == '__main__':
    main()
