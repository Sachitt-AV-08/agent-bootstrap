/**
 * {{PROJECT_NAME}} - {{PROJECT_DESCRIPTION}}
 */

export function greet(name: string = "World"): string {
  return `Hello, ${name}!`;
}

export function main(argv: string[] = process.argv.slice(2)): number {
  const args = parseArgs(argv);
  
  if (args.help) {
    printHelp();
    return 0;
  }
  
  if (args.version) {
    console.log("0.1.0");
    return 0;
  }
  
  const name = args._[0] ?? "World";
  console.log(greet(name));
  
  return 0;
}

interface ParsedArgs {
  _: string[];
  help: boolean;
  version: boolean;
}

function parseArgs(argv: string[]): ParsedArgs {
  const result: ParsedArgs = { _: [], help: false, version: false };
  
  for (const arg of argv) {
    if (arg === "-h" || arg === "--help") {
      result.help = true;
    } else if (arg === "-v" || arg === "--version") {
      result.version = true;
    } else if (!arg.startsWith("-")) {
      result._.push(arg);
    }
  }
  
  return result;
}

function printHelp(): void {
  console.log(`
Usage: {{PACKAGE_NAME}} [options] [name]

Options:
  -h, --help     Show this help
  -v, --version  Show version

Examples:
  {{PACKAGE_NAME}}           # Hello, World!
  {{PACKAGE_NAME}} Alice     # Hello, Alice!
`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  process.exit(main());
}