## Template: Python 3.12+ (uv)

You are operating within a Python codebase. Adhere to these standards on top of the global standards.

## Python Standards

1. **Version**: Assume Python 3.12+. Use modern syntax: `match`, `typing.Self`, `tomllib`, `pathlib` over `os.path`.
2. **Package management**: Use `uv` exclusively — `uv add`, `uv run`, `uv sync`. Never use `pip install` directly. The virtualenv lives at `.venv/` and is managed by uv.
3. **Project structure**: Use a `src/` layout (`src/<package>/`) with `pyproject.toml` at root. No `setup.py`.
4. **Formatting / linting**: Ruff handles formatting, linting, and import sorting. Config lives in `pyproject.toml` under `[tool.ruff]`. Do not add black, isort, or flake8.
5. **Type hints**: All public functions and methods must have type annotations. Use `from __future__ import annotations` at the top of every file.
6. **Testing**: pytest with `tests/` at project root. Fixtures in `conftest.py`. Use `uv run pytest`.
7. **Error handling**: Raise specific exceptions. Never use bare `except:`. Prefer explicit error types over generic `Exception`.
8. **pyproject.toml**: Always declare `requires-python = ">=3.12"`. Pin direct dependencies with minimum versions (`>=`), not exact pins (`==`), unless reproducibility is critical.
