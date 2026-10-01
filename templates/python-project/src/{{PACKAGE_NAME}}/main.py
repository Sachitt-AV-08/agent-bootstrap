"""Main module for {{PROJECT_NAME}}."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main(argv: list[str] | None = None) -> int:
    """Entry point."""
    parser = argparse.ArgumentParser(
        prog="{{PACKAGE_NAME}}",
        description="{{PROJECT_DESCRIPTION}}",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output",
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=Path,
        help="Input file (default: stdin)",
    )
    
    args = parser.parse_args(argv)
    
    if args.verbose:
        print(f"Running {{PROJECT_NAME}} v0.1.0", file=sys.stderr)
    
    # Your code here
    print("Hello from {{PROJECT_NAME}}!")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())