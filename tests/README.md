# Idempotency tests

These tests verify the contract that every installer/entrypoint shares:

- running an install twice never fails,
- an already-installed tool causes no download, clone, or package-manager call,
- the empty stub files created by the old simulated handler are removed.

## Unix

```bash
bash tests/run-idempotency.sh
```

The test fakes installed executables in a temporary `HOME` and stubs `curl`
so any accidental network call becomes a hard failure.

## Windows

```powershell
.\tests\run-idempotency.ps1
```

It uses a temporary `HOME`, fake executables, and overrides `winget`,
`Invoke-RestMethod`, and `Invoke-WebRequest` to fail if called.
