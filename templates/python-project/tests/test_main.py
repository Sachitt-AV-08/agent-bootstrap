"""Tests for {{PROJECT_NAME}}."""

import pytest
from {{PACKAGE_NAME}}.main import main


def test_main_runs(monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]) -> None:
    """Test that main runs without error."""
    # Simulate command line args
    monkeypatch.setattr("sys.argv", ["{{PACKAGE_NAME}}"])
    
    exit_code = main()
    
    assert exit_code == 0
    captured = capsys.readouterr()
    assert "Hello from {{PROJECT_NAME}}!" in captured.out


def test_main_verbose(monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]) -> None:
    """Test verbose flag."""
    monkeypatch.setattr("sys.argv", ["{{PACKAGE_NAME}}", "-v"])
    
    exit_code = main()
    
    assert exit_code == 0
    captured = capsys.readouterr()
    assert "Running {{PROJECT_NAME}} v0.1.0" in captured.err