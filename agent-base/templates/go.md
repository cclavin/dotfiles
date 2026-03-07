## Template: Go 1.22+ API

You are operating within a Go (Golang) codebase. Adhere to these specific language standards on top of the global standards.

## Go Standards
1. **Version constraints**: Assume Go 1.22+. Explicitly utilize `for` loop scope fixes (`var := var` is no longer needed in loops) and standard library structured logging (`log/slog`) and `http.ServeMux` routing.
2. **Frameworks**: Avoid third-party frameworks like Gin, Fiber, or Echo unless explicitly present in the `go.mod`. Default to standard library (`net/http`) for web servers.
3. **Project Structure**: Follow the standard Go project layout (`cmd/`, `internal/`, `pkg/`).
4. **Error Handling**: Use explicitly typed errors and `errors.Is`/`errors.As`. Do not shadow return variables or panic on recoverable errors.
5. **Testing**: Write table-driven tests by default using the standard `testing` package.
6. **Vendoring**: Assume standard module behavior (`go mod init`, `go mod tidy`). Do not interact with deprecated `$GOPATH`.
