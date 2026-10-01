#!/usr/bin/env bash
# Create a new project from template

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <name> [template] [options]
Templates: python (default), node, basic
Options:
  --description "Description"
  --author "Author Name"
  --email "email@example.com"
  -h, --help    Show this help
EOF
}

NAME=""
TEMPLATE="python"
DESCRIPTION=""
AUTHOR="${USER}"
EMAIL="${USER}@users.noreply.github.com"

while [[ $# -gt 0 ]]; do
    case $1 in
        --description) DESCRIPTION="$2"; shift 2 ;;
        --author) AUTHOR="$2"; shift 2 ;;
        --email) EMAIL="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)
            if [[ -z "$NAME" ]]; then
                NAME="$1"
            elif [[ -z "$TEMPLATE" || "$TEMPLATE" == "python" ]]; then
                TEMPLATE="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$NAME" ]]; then
    usage
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/projects"
PROJECT_DIR="$PROJECT_ROOT/$NAME"
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/templates/${TEMPLATE}-project"

if [[ -d "$PROJECT_DIR" ]]; then
    echo "Error: Project '$NAME' already exists at $PROJECT_DIR" >&2
    exit 1
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo "Error: Template '$TEMPLATE' not found at $TEMPLATE_DIR" >&2
    exit 1
fi

PACKAGE_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[- ]/_/g')
DESC="${DESCRIPTION:-A $TEMPLATE project: $NAME}"

echo "Creating project '$NAME' from '$TEMPLATE' template..."

# Copy template
cp -r "$TEMPLATE_DIR" "$PROJECT_DIR"

# Template replacements
find "$PROJECT_DIR" -type f -name "*" ! -path "*/node_modules/*" ! -path "*/.git/*" | while IFS= read -r file; do
    sed -i "s/{{PROJECT_NAME}}/$NAME/g" "$file"
    sed -i "s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g" "$file"
    sed -i "s/{{PROJECT_DESCRIPTION}}/$DESC/g" "$file"
    sed -i "s/{{AUTHOR}}/$AUTHOR/g" "$file"
    sed -i "s/{{EMAIL}}/$EMAIL/g" "$file"
done

# Rename files with template vars
find "$PROJECT_DIR" -depth -name "*{{*}}*" | while IFS= read -r file; do
    newfile=$(echo "$file" | sed "s/{{PROJECT_NAME}}/$NAME/g; s/{{PACKAGE_NAME}}/$PACKAGE_NAME/g")
    if [[ "$file" != "$newfile" ]]; then
        mv "$file" "$newfile"
    fi
done

# Rename package directory for Python
if [[ "$TEMPLATE" == "python" ]]; then
    oldpkg=$(find "$PROJECT_DIR/src" -maxdepth 1 -type d -name '{{PACKAGE_NAME}}' 2>/dev/null || true)
    if [[ -n "$oldpkg" ]]; then
        mv "$oldpkg" "$PROJECT_DIR/src/$PACKAGE_NAME"
    fi
fi

# Initialize git
cd "$PROJECT_DIR"
git init -q
git add -A
git commit -m "Initial commit from $TEMPLATE template" -q

echo "✓ Project created at $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_DIR"
if [[ "$TEMPLATE" == "python" ]]; then
    echo "  uv sync --dev"
    echo "  uv run pytest"
elif [[ "$TEMPLATE" == "node" ]]; then
    echo "  npm install"
    echo "  npm test"
fi
echo "  opencode"